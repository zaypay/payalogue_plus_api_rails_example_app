require 'test_helper'

class PurchaseTest < ActiveSupport::TestCase
  
  context "update_status_by_valid_request" do
    setup do
      @purchase = Purchase.first
    end

    context "params[:product_id] of incoming request does not match purchase.product_id" do
      should "NOT instantiate a price_setting" do
        params = {:product_id => '2', :price_setting_id => '444444', :status => "prepared", :payment_id => '12345'}
        Zaypay::PriceSetting.expects(:new).never
        @purchase.update_status_by_valid_request(params)
      end
    end

    context "params[:price_setting_id] of incoming request does not match purchase.product.price_setting_id" do
      should "NOT instantiate a price_setting" do
        params = {:product_id => '1', :price_setting_id => '333333', :status => "prepared", :payment_id => '12345'}
        Zaypay::PriceSetting.expects(:new).never
        @purchase.update_status_by_valid_request(params)
      end
    end

    context "params of product_id AND price_setting_id are valid" do
      setup do
        @payment = {:payment => {:id => '12345', :status => "prepared"}}
        @price_setting_mock = dutch_price_setting_mock
        Zaypay::PriceSetting.stubs(:new).returns @price_setting_mock
      end

      context "params[:status] in request == payment status on zaypay platform" do
        setup do 
          @params =  {:product_id => '1', :price_setting_id => '222222', :status => "prepared", :payment_id => '12345' } 
        end
        should "update status and save it" do
          @price_setting_mock.expects(:show_payment).with(12345).returns @payment
          @purchase.update_status_by_valid_request(@params)
          assert_equal "prepared", @purchase.reload.status
        end
      end

      context "params[:status] in request != payment status on zaypay platform" do
        setup do 
          @params =  {:product_id => '1', :price_setting_id => '222222', :status => "paid", :payment_id => '12345' } 
        end
        should "not update status" do
          @price_setting_mock.expects(:show_payment).with(12345).returns @payment
          @purchase.update_status_by_valid_request(@params)
          assert_not_equal "paid", @purchase.reload.status
        end
      end

    end
  end
end
