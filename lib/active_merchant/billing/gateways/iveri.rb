module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class IveriGateway < Gateway
      
      TEST_URL = "https://gateway.iveri.co.za/iVeriWebService/Service.asmx"
      LIVE_URL = "https://gateway.iveri.co.za/iVeriWebService/Service.asmx"
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['ZA']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.iveri.co.za/'
      
      # The name of the gateway
      self.display_name = 'iVeri'
      
      def initialize(options = {})
        requires!(options, :certificate_id, :application_id)
        @options = options
        super
      end  
      
      def authorize(money, creditcard, options = {})
        # TODO
      end
      
      def purchase(money, creditcard, options = {})
        requires!(options, :reference)
        purchase_request = build_purchase_request(money, creditcard, options)
        soap_request = build_soap_request(purchase_request.to_s)
        
        commit(soap_request)
      end                       
    
      def capture(money, authorization, options = {})
        # TODO
      end
    
      private

      def build_soap_request(v_xml)
        xml = Builder::XmlMarkup.new
        xml.tag! "SOAP-ENV:Envelope" , "xmlns:SOAP-ENV" => "http://schemas.xmlsoap.org/soap/envelope/" do
          xml.tag! "SOAP-ENV:Header/"
          xml.tag! "SOAP-ENV:Body" do
            xml.tag! "Execute", "xmlns" => "http://iveri.com/" do
              xml.tag! "validateRequest", true
              xml.tag! "protocol", "V_XML"
              xml.tag! "protocolVersion", "2.0"
              xml.tag! "request", v_xml
            end
          end
        end
      end
      
      def build_v_xml_request(transaction_type, &block)
        xml = Builder::XmlMarkup.new
        xml.tag! "V_XML", :Version => "2.0", :CertificateID => @options[:certificate_id], :ProductVersion => "iVeri Client 2.3.5", :Direction => "Request" do
          xml.tag! "Transaction", :Command => transaction_type.capitalize, :Mode => (test? ? "Test" : "Live"), :ApplicationID => @options[:application_id] do
            yield xml if block_given?
          end
        end
      end
      
      def build_purchase_request(money, creditcard, options)
        build_v_xml_request("Debit") do |xml|
          add_invoice(xml, options)
          add_amount(xml, money)
          add_creditcard(xml, creditcard)
        end
      end

      def add_invoice(xml, options)
        xml.tag! "MerchantReference", options[:reference]
      end
      
      def add_creditcard(xml, creditcard)
        cc_month = creditcard.month < 10 ? "0#{creditcard.month}" : creditcard.month.to_s
        
        xml.tag! "CCNumber", creditcard.number
        xml.tag! "ExpiryDate", cc_month + creditcard.year.to_s
        xml.tag! "CardSecurityCode", creditcard.verification_value
      end
      
      def add_amount(xml, money)
        xml.tag! "Currency", "ZAR"
        xml.tag! "Amount", money
      end
      
      def parse(body)
      end     
      
      def commit(request)
        response = parse(ssl_post(test? ? TEST_URL : LIVE_URL, request))
        
        # TODO: Response.new
      end

      def message_from(response)
      end
    end
  end
end

