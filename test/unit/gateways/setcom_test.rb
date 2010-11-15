require 'test_helper'

class SetcomTest < Test::Unit::TestCase
  def setup
    @gateway = SetcomGateway.new(
                 :company_id => 'login',
                 :outlet => 'password'
               )

    @credit_card = credit_card
    @amount = 100
    
    @options = { 
      :reference => "test123"
    }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    
    # Replace with authorization number from the successful response
    assert_equal '10160810', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  private
  
  # Place raw successful response from gateway here
  def successful_purchase_response
    "Approved,123456,15/11/2010,15:44:07 PM,10160810,5EDD-A1A2,150.00"
  end
  
  # Place raw failed response from gateway here
  def failed_purchase_response
    "Declined,123456,15/11/2010,15:44:07 PM,0,5EDD-A1A2,150.00"
  end
end
