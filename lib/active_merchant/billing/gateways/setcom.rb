module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class SetcomGateway < Gateway
      TEST_URL = 'https://secure.setcom.co.za/server.cfm'
      LIVE_URL = 'https://secure.setcom.co.za/server.cfm'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['ZA']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.setcom.co.za/'

      # The name of the gateway
      self.display_name = 'Setcom'

      ERRORS = {
        "32002" => "Phone the bank for manual authorisation",
        "32003" => "Card blocked",
        "32005" => "Card expired",
        "32008" => "Card too new",
        "32011" => "Transaction declined",
        "32013" => "Hold and call the bank",
        "32024" => "Invalid card number",
        "32027" => "Invalid expiry date",
        "32047" => "Card has been reported lost",
        "32048" => "Card has been reported stolen",
        "32049" => "Card has been reported lost or stolen",
        "32051" => "Unable to connect to the bank. Please call Setcom.",
        "32057" => "Incorrect card number, please re-type",
        "32063" => "Connection to the bank timed out. Please retry.",
        "30001" => "Unable to connect to the Gateway. Please call Setcom.",
        "30006" => "Connection to the bank timed out. Please retry.",
        "10102" => "The merchant / outlet could not be found on the system"
      }

      def initialize(options = {})
        requires!(options, :company_id, :outlet)
        @options = options
        super
      end  

      def authorize(money, creditcard, options = {})
        raise 'Setcom only supports purchase'
        # post = {}
        # add_authentication_details(post)
        # add_invoice(post, options)
        # add_creditcard(post, creditcard)
        # 
        # commit('authonly', money, post)
      end

      def purchase(money, creditcard, options = {})
        requires!(options, :reference)

        post = {}
        add_authentication_details(post)
        add_invoice(post, options)
        add_money(post, money)
        add_creditcard(post, creditcard)

        commit('sale', post)
      end                       

      def capture(money, authorization, options = {})
        raise 'Setcom only supports purchase'
        #commit('capture', money, post)
      end

      private

      def add_authentication_details(post)
        post[:CO_ID] = @options[:company_id]
        post[:Outlet] = @options[:outlet]
      end

      def add_invoice(post, options)
        post[:Reference] = options[:reference]
      end

      def add_money(post, money)
        post[:CC_Amount] = money
      end

      def add_creditcard(post, creditcard)
        post[:CCname] = "#{creditcard.first_name} #{creditcard.last_name}"
        post[:CCnumber] = creditcard.number
        post[:CCCVV] = creditcard.verification_value
        post[:CCtype] = creditcard.type
        post[:ExMonth] = creditcard.month
        post[:ExYear] = creditcard.year
      end

      def parse(body)
        response = {}
        r = body.split(/,/).each(&:strip!)

        result, auth_number, date, time, order_id, reference, amount = r

        response[:success] = result.downcase.include?("approved")
        response[:message] = message_from(result, auth_number)
        response[:authorization] = order_id

        response
      end     

      def commit(action, parameters)
        url = test? ? TEST_URL : LIVE_URL

        response = parse(ssl_post(url, post_data(action, parameters)))

        options = { :test => test?, :authorization => response[:authorization]}

        Response.new(response[:success], response[:message], response, options)
      end

      def message_from(result, auth_number)
        if result.downcase.include?("error")
          errors = ERRORS.select{ |k,v| k.to_s == auth_number.to_s }.first

          errors.nil? ? "Unknown Error: ##{auth_number}" : errors[1]
        end
      end

      def post_data(action, parameters = {})
        parameters.reject{|k,v| v.blank?}.collect{ |k, v| "#{k.to_s}=#{CGI.escape(v.to_s)}" }.join("&")
      end
    end
  end
end

