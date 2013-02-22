require 'timeout'

module Em
  module Zimbreasy
    class Account
      attr_accessor :user, :pass, :endpoint, :client, :soap_namespace, :zimbra_namespace

      def initialize(user, pass, endpoint)
        @user = user
        @pass = pass
        @endpoint = endpoint
        @soap_namespace = {
          "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/"
        }
        @zimbra_namespace = "urn:zimbraAccount"
        auth_request
      end
    
      def auth_request
        make_call(
          :AuthRequest, 
          { :persistAuthTokenCookie => 1, :xmlns => @zimbra_namespace },
          {
            :account => @user, 
            :password => @pass,
            :attributes! => { :account => { :by => "name" } }
          }
        )
      end

      def make_call(method, attrs={}, message)
        tries = 0
        soap_namespace = @soap_namespace 
        #@soap_namespace is undefined inside client.request, is not this obj. So we define it here.

        @client ||= Savon.client(
          namespace_identifier: :none,
				  pretty_print_xml: true, 
				  log: false, 
				  endpoint: @endpoint, 
				  namespace: soap_namespace,
				  convert_request_keys_to: :none
			  )

        response = @client.call(method, attributes: attrs, message: message)

      rescue Timeout::Error => e
        pp "Retrying"
        tries+=1
        if tries >= 4
          throw ZimbreasyTimeoutException.new
        else
          retry
        end
      end
    end
  end
end
