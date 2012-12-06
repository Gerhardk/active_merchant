module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PayuGateway < Gateway
      LIVE_URL = 'https://secure.SafeShop.co.za/s2s/SafePay.asp'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['ZA']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.payu.co.za/'

      # The name of the gateway
      self.display_name = 'PayU'

      def initialize(options = {})
        requires!(options, :safe_key)
        @options = options

        super
      end

      def test?
        @options[:test] || Base.gateway_mode == :test
      end

      def authorize(money, creditcard, options = {})
        raise "Only supports purchase"
      end

      def purchase(money, creditcard, options = {})
        requires!(options, :reference)
        request = build_purchase_request(money, creditcard, options)

        commit(request)
      end

      def capture(money, authorization, options = {})
        raise "Only supports purchase"
      end

      private

      def build_purchase_request(money, creditcard, options)
        xml = Builder::XmlMarkup.new :indent => 2

        xml.tag! "Safe" do
          xml.tag! "Merchant" do
            xml.tag! "SafeKey", @options[:safe_key]
          end
          xml.tag! "Transactions" do
            xml.tag! "Auth_Settle" do
              xml.tag! "MerchantReference", options[:reference]
              xml.tag! "Amount", money
              xml.tag! "CardHolderName", creditcard.name
              xml.tag! "BuyerCreditCardNr", creditcard.number
              xml.tag! "BuyerCreditCardExpireDate", "#{creditcard.month}#{creditcard.year}"
              xml.tag! "BuyerCreditCardCVV2", creditcard.verification_value
              xml.tag! "LiveTransaction", !test?
            end
          end
        end

        xml.target!
      end

      def parse(body)
        puts body.inspect
        response = {}

        xml = REXML::Document.new(body)

        xml.elements.each('//Safe/Transactions/*') do |node|
          response[node.name.downcase.to_sym] = normalize(node.text)
        end unless xml.root.nil?

        response
      end

      def commit(request)
        puts request.inspect
        response = parse( ssl_post(LIVE_URL, request) )

        puts response.inspect

        success = response[:transactionresult] == "Successful" ? true : false
        Response.new(success, message_from(response), response, :test => test?, :authorization => response[:safepayrefnr])
      end

      def message_from(response)
        response[:transactionerrorresponse].blank? ? "" : response[:transactionerrorresponse]
      end

      def normalize(field)
        case field
        when "true"   then true
        when "false"  then false
        when ""       then nil
        when "null"   then nil
        else field
        end        
      end
    end
  end
end

