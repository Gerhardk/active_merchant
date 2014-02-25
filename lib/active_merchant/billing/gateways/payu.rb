module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PayuGateway < Gateway
      # LIVE_URL = 'https://secure.SafeShop.co.za/s2s/SafePay.asp'
      LIVE_URL = 'http://staging.safeshop.co.za/s2s/SafePay.asp'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['ZA']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.payu.co.za/'

      # The name of the gateway
      self.display_name = 'PayU'

      BANK_ERROR_CODES = {
        "01" => "Refer to card issuer",
        "02" => "Refer to card issuer, special condition",
        "03" => "Invalid merchant",
        "04" => "Pick-up card",
        "05" => "Do not honor",
        "06" => "Error",
        "07" => "Pick-up card, special condition",
        "08" => "Honor with identification",
        "09" => "Request in progress",
        "10" => "Approved, partial",
        "11" => "Approved, VIP",
        "12" => "Invalid transaction",
        "13" => "Invalid amount",
        "14" => "Invalid card number",
        "15" => "No such issuer",
        "16" => "Approved, update track 3",
        "17" => "Customer cancellation",
        "18" => "Customer dispute",
        "19" => "Re-enter transaction",
        "20" => "Invalid response",
        "21" => "No action taken",
        "22" => "Suspected malfunction",
        "23" => "Unacceptable transaction fee",
        "24" => "File update not supported",
        "25" => "Unable to locate record",
        "26" => "Duplicate record",
        "27" => "File update edit error",
        "28" => "File update file locked",
        "29" => "File update failed",
        "30" => "Format error",
        "31" => "Bank not supported",
        "32" => "Completed partially",
        "33" => "Expired card, pick-up",
        "34" => "Suspected fraud, pick-up",
        "35" => "Contact acquirer, pick-up",
        "36" => "Restricted card, pick-up",
        "37" => "Call acquirer security, pick-up",
        "38" => "PIN tries exceeded, pick-up",
        "39" => "No credit account",
        "40" => "Function not supported",
        "41" => "Lost card",
        "42" => "No universal account",
        "43" => "Stolen card",
        "44" => "No investment account",
        "45" => "Account closed",
        "46" => "Reserved for client-specific use (declined)",
        "47" => "Reserved for client-specific use (declined)",
        "48" => "Reserved for client-specific use (declined)",
        "49" => "Reserved for client-specific use (declined)",
        "50" => "Reserved for client-specific use (declined)",
        "51" => "Insufficient funds",
        "52" => "No check account",
        "53" => "No savings account",
        "54" => "Expired card",
        "55" => "Incorrect PIN",
        "56" => "No card record",
        "57" => "Transaction not permitted to cardholder",
        "58" => "Transaction not permitted on terminal",
        "59" => "Suspected fraud",
        "60" => "Contact acquirer",
        "61" => "Exceeds withdrawal limit",
        "62" => "Restricted card",
        "63" => "Security violation",
        "64" => "Original amount incorrect",
        "65" => "Exceeds withdrawal frequency",
        "66" => "Call acquirer security",
        "67" => "Hard capture",
        "68" => "Response received too late",
        "69" => "Advice received too late",
        "70" => "Permission denied",
        "71" => "Reserved for Bank use (declined)",
        "72" => "Reserved for Bank use (declined)",
        "73" => "Reserved for Bank use (declined)",
        "74" => "Reserved for Bank use (declined)",
        "75" => "PIN tries exceeded",
        "76" => "Reserved for Bank use (declined)",
        "77" => "Intervene, bank approval required",
        "78" => "Intervene, bank approval required for partial amount",
        "79" => "Reserved for Bank use (declined)",
        "80" => "Reserved for Bank use (declined)",
        "81" => "Reserved for Bank use (declined)",
        "82" => "Reserved for Bank use (declined)",
        "83" => "Your bank has indicated that your card was not found on its Cardholder Authorisation File",
        "84" => "Reserved for Bank use (declined)",
        "85" => "Reserved for Bank use (declined)",
        "86" => "Reserved for Bank use (declined)",
        "87" => "Bad track information.",
        "88" => "Reserved for Bank use (declined)",
        "89" => "Your bank has indicated that invalid data was sent to them",
        "90" => "Cut-off in progress",
        "91" => "Issuer or switch inoperative",
        "92" => "Routing error",
        "93" => "Violation of law",
        "94" => "Duplicate transaction",
        "95" => "Reconcile error",
        "96" => "Your bank has returned a 'System malfunction' error",
        "97" => "Reserved for Bank use (declined)",
        "98" => "Exceeds cash limit",
        "A1" => "ATC not incremented",
        "A2" => "ATC limit exceeded",
        "A3" => "ATC configuration error",
        "A4" => "CVR check failure",
        "A5" => "CVR configuration error",
        "A6" => "TVR check failure",
        "A7" => "TVR configuration error",
        "C1" => "PIN Change failed",
        "C2" => "PIN Unblock failed",
        "D1" => "MAC Error",
        "E1" => "Prepay error"
      }

      def initialize(options = {})
        requires!(options, :safe_key)
        @options = options

        super
      end

      def test?
        Base.gateway_mode == :test
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
              xml.tag! "BuyerCreditCardExpireDate", card_expiry_number(creditcard)
              xml.tag! "BuyerCreditCardCVV2", creditcard.verification_value
              xml.tag! "LiveTransaction", !test?
            end
          end
        end

        xml.target!
      end

      def card_expiry_number(creditcard)
        month = '%02d' % creditcard.month

        "#{month}#{creditcard.year}"
      end

      def parse(body)
        response = {}
        body.force_encoding("utf-8")

        xml = REXML::Document.new(body)

        xml.elements.each('//Safe/Transactions/*') do |node|
          response[node.name.downcase.to_sym] = normalize(node.text)
        end unless xml.root.nil?

        response
      end

      def commit(request)
        response = parse( ssl_post(LIVE_URL, request) )

        success = response[:transactionresult] == "Successful" ? true : false
        Response.new(success, message_from(response), response, :test => test?, :authorization => response[:safepayrefnr])
      end

      def message_from(response)
        message = response[:transactionerrorresponse] unless response[:transactionerrorresponse].blank?
        message ||= BANK_ERROR_CODES[response[:financialinstitutionresponse]]

        message
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