require_dependency "#{Rails.root}/app/models/report/ext"
Dir.glob("#{Rails.root}/app/models/report/component/*.rb").each{|c| require_dependency c}
Dir.glob("#{Rails.root}/app/models/report/ofc/*.rb").each{|c| require_dependency c}

module Report

=begin rdoc
=Report

Base class for all reports.

=end
class Base
  include Report::Ext
  
  # Valid components (also needs to be loaded for caching/marshal)

  VALID_COMPONENTS = [ Report::Component::Text,
                       Report::Component::Table,
                       Report::Component::Formatting,
                       Report::Component::Parameters,
                       Report::Component::Meta,
                       Report::OFC::Bar,
                       Report::OFC::Bar::Results,
                       Report::OFC::BarStack,
                       Report::OFC::Line,
                       Report::OFC::Line::Multi ]

  def expires_in; Testia::DEFAULT_REPORT_CACHE_TIME; end

  # Constructor. Call in subclasses' constructors.
  def initialize(opts = {})
    @data = nil
    @name = 'Unknown'
  end

  # override for pdf option changes
  def pdf_options
    {:opts_for_new => {:page_layout => :landscape}}
  end

  def meta
    @data ||= []
    mc = @data.detect{|d| d.is_a?(Report::Component::Meta)}
    unless mc
      mc = Report::Component::Meta.new
      add_component(mc)
    end
    mc
  end

  def charts
    c = @data.select{|comp| comp.is_a?(Report::OFC::Base)}
    # sets the image post url for each of the chart components
    # appends the chart's image key to the url
    def c.image_post_url=(url)
      self.each {|c| c.image_post_url = url+c.chart_image_key}
    end
    c
  end

  def tables
    t = @data.select{|comp| comp.is_a?(Report::Component::Table)}
    # sets the csv export url for each table components
    # appends table index number to the url
    def t.csv_export_url=(url)
      self.each_with_index{|t,i| t.csv_export_url = url+i.to_s}
    end
    t
  end

  def row(x, table_num=0)
    tbl = self.tables
    raise "Only #{t.size} tables! (index #{table_num} tried)" if tbl.size <= table_num
    tbl[table_num].data[x]
  end

  def to_data
    self.query unless @data
    return @data
  end
  alias_method :components, :to_data

  def to_csv(table=0, delimiter=';', line_feed="\r\n")
    self.query unless @data
    tables[table].to_csv(delimiter, line_feed)
  end

  def to_pdf
    self.query unless @data
    Report::PDF.new(self, self.pdf_options).render
  end

  def to_spreadsheet
    self.query unless @data
    Report::Excel.new(self).render
  end

  # wraps components in a 'report' element and converts to json
  def as_json(options=nil)
    self.query unless @data
    {:type => 'report', :components => @data}.as_json(options)
  end

  # make the query (a template method)
  # caches the results for time of self.expires_in
  def query
    if self.expires_in == 0.seconds
      do_query
      return
    end
    
    if Rails.cache.is_a?(ActiveSupport::Cache::MemCacheStore)
      @data = Rails.cache.fetch(self.cache_key, :expires_in => self.expires_in) do
        self.do_query
        @data
      end
    else
      # TODO: Marshal load/dump not required anymore when MemoryStore does it
      #       by default.
      expires_at = Rails.cache.read("#{self.cache_key}_expires_at")
      if expires_at and (expires_at > Time.now) and \
          (data = Rails.cache.read(self.cache_key))
        @data = Marshal.load(data)
      else
        do_query
        Rails.cache.write(self.cache_key, Marshal.dump(@data))
        Rails.cache.write("#{self.cache_key}_expires_at", Time.now + self.expires_in)
      end
    end
  end

  # update values of editable text fields if POSTed data found
  def update!(project, user)
    rdata = Report::Data.find(:last, :conditions => {
      :user_id => user.id, :project_id => project.id, :key => self.cache_key})

    return if !rdata or !rdata.data

    rdata.data.each do |k, v|
      if comp = @data.detect{|c| c.is_a?(Report::Component::Text) and c.key == k}
        comp.value = v
      else
        raise "No text component with key '#{k}'!"
      end
    end
  end

  def data_post_url=(url); self.meta.data_post_url = (url+self.cache_key) end

  def cache_key
    @cache_key ||= begin
      opt_str = ''
      (@options || {}).keys.map(&:to_s).
        sort.each{|key| opt_str += "#{key}#{@options[key.to_sym]}"}
      Digest::MD5.hexdigest("#{self.class.to_s.underscore}#{opt_str}")
    end               
  end
  
  protected

  def add_component(comp)
    raise "#{comp.class} is not a valid report component!" \
      unless VALID_COMPONENTS.include?(comp.class)

    @data ||= []
    idx = @data.size

    if comp.is_a?(Report::OFC::Base)
      # Set the chart image key which enables mapping charts to images
      comp.chart_image_key = ChartImage.create_key(cache_key, idx)
      # Key in charts is used for storing chart scaling in cookies (UI)
      comp.key = "#{self.class.to_s.underscore}/#{idx}"

    elsif comp.is_a?(Report::Component::Text) and comp.editable
      # Set the key so that editable values can be updated
      comp.key = "#{self.class.to_s.underscore}/#{idx}"

    elsif comp.is_a?(Report::Component::Parameters)
      comp.parent_name = @name if comp.name != @name
    end
    @data = @data + [comp]
    comp
  end

  def add_subreport(rep)
    rep.components.each{|c| add_component(c)}
  end

  ### Here be the shortcuts for adding components ###
  def h1(*args)
    add_component(Report::Component::Text.new(:h1, *args))
  end
  def h2(*args)
    add_component(Report::Component::Text.new(:h2, *args))
  end
  def h3(*args)
    add_component(Report::Component::Text.new(:h3, *args))
  end
  def text(*args)
    add_component(Report::Component::Text.new(:p, *args))
  end
  def show_params(*key_val_arrs)
    add_component(Report::Component::Parameters.new(@name, key_val_arrs))
  end
  def page_break
    add_component(Report::Component::Formatting.new(:page_break => true))
  end
  def pad(pad_amt)
    add_component(Report::Component::Formatting.new(:pad => pad_amt))
  end
  def text_options(h)
    add_component(Report::Component::Formatting.new(:text_options => h))
  end
  def t(*args)
    add_component(Report::Component::Table.new(*args))
  end
  def bar_chart(*args)
    add_component(Report::OFC::Bar.new(*args))
  end
  def bar_chart_results(*args)
    add_component(Report::OFC::Bar::Results.new(*args))
  end
  def bar_stack_chart(*args)
    add_component(Report::OFC::BarStack.new(*args))
  end
  def line_chart(*args)
    add_component(Report::OFC::Line.new(*args))
  end
  ###################################################

end


end # module Report
