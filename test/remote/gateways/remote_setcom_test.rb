require 'test_helper'

class RemoteSetcomTest < Test::Unit::TestCase
  
  # Setcom only supports purchase
  def setup
    @gateway = SetcomGateway.new(fixtures(:setcom))
    
    @amount = 100
    @credit_card = credit_card('4111111111111111')
    @declined_card = credit_card('4222222222222222')
    
    @options = { 
      :reference => "livetestactivemerchant"
    }
  end
  
  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal nil, response.message
  end

  def test_unsuccessful_purchase
    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'Incorrect card number, please re-type', response.message
  end

  # def test_authorize_and_capture
  #     amount = @amount
  #     assert auth = @gateway.authorize(amount, @credit_card, @options)
  #     assert_success auth
  #     assert_equal 'Success', auth.message
  #     assert auth.authorization
  #     assert capture = @gateway.capture(amount, auth.authorization)
  #     assert_success capture
  #   end
  # 
  #   def test_failed_capture
  #     assert response = @gateway.capture(@amount, '')
  #     assert_failure response
  #     assert_equal 'REPLACE WITH GATEWAY FAILURE MESSAGE', response.message
  #   end

  def test_invalid_login
    gateway = SetcomGateway.new(
                :company_id => '',
                :outlet => ''
              )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal 'Unknown Error: #10101', response.message
  end
end
