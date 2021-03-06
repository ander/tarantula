### CUSTOMER SPECIFIC SETTINGS (from environment.rb) ###

# SMTP Settings.
# Needed for automatic notifications (user logins and passwords
# are sent by email).

module Testia
  # SERVER ROOT URL.
  # This is used in notifications sent by server to new user
  # accounts (where application is available to users).
  port = CustomerConfig.port.blank? ? '' : ":#{CustomerConfig.port}" 
  WWW_SERVER="#{CustomerConfig.protocol}://#{CustomerConfig.host}#{port}"
  
  # WWW server directory from where Testia application is available.
  # If application is installed to www root, this is empty string.
  # If application is available from subdir, specify directory with
  # leading slash. E.g. WWW_PATH = '/testia'
  #
  # Used by client to address requests correctly. 
  #
  WWW_PATH= ''

  # Tool administrators email address.
  # Is used by automatic notifications
  ADMIN_EMAIL = CustomerConfig.admin_email
  
  # How many items to load at once at tagged lists.
  # No need to change this.
  LOAD_LIMIT = 500
  
  DEFAULT_REPORT_CACHE_TIME = 1.minute
end