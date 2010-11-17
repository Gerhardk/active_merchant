require 'test_helper'

class IveriTest < Test::Unit::TestCase
  def setup
    @gateway = IveriGateway.new(
                 :certificate_id => '{E9CCD42C-8E5C-4E36-9CE6-96B45B7ADDB1}',
                 :application_id => 'AF8E6E69-ADC5-4D4F-B446-43D2E1E598D3'
               )

    @credit_card = credit_card
    @amount = 100
    
    @options = { 
      :reference => "12345",
    }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of 
    assert_success response
    
    # Replace with authorization number from the successful response
    assert_equal '', response.authorization
    assert response.test?
  end

  # def test_unsuccessful_request
  #   @gateway.expects(:ssl_post).returns(failed_purchase_response)
  #   
  #   assert response = @gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   assert response.test?
  # end

  private
  
  # Place raw successful response from gateway here
  def successful_purchase_response
  end
  
  # Place raw failed response from gateway here
  def failed_purcahse_response
  end
end
