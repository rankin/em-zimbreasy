require "icalendar"
require "exceptions/zimbreasy_timeout_exception"
require "em-zimbreasy/version"
require "em-zimbreasy/mail"
require "em-zimbreasy/account"

module Em
  module Zimbreasy
	  HTTPI::Adapter.use = :em_http
    
	  #takes a Time object. outputs string for zimbra api calls.
    def self.zimbra_date(time)
      time.strftime("%Y%m%dT%H%M%S")
    end

    
  end
end
