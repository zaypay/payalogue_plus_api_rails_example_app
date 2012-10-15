require 'test_helper'

class PurchasesControllerTest < ActionController::TestCase

  setup do
    @product = products(:one)
    @price_setting = dutch_price_setting_mock
    Zaypay::PriceSetting.stubs(:new).returns @price_setting
  end

  context "#new" do 
    should "assign a price_setting" do
      get :new, :product_id => @product
      assert_not_nil assigns(:ps)
    end
    should "be successful and render new" do
      get :new, :product_id => @product
      assert_response :success
      assert_template :new
    end

    context ".html" do
      context "ip_country is configured the in price setting" do
        should "set locale to the ip-country" do
          Zaypay::PriceSetting.stubs(:new).returns @price_setting
          @price_setting.expects(:ip_country_is_configured?).returns({:country => {:name => 'Netherlands', :code => 'NL'}, 
                                                           :locale => {:country => 'NL', :language => 'nl'}})
          @price_setting.expects(:locale=)
          get :new, :product_id => @product
        end
      end
      context "ip country is not configured in price setting" do
        should "not assign locale" do
          Zaypay::PriceSetting.stubs(:new).returns @price_setting
          @price_setting.expects(:ip_country_is_configured?).returns nil
          @price_setting.expects(:locale=).never
          get :new, :product_id => @product
        end
      end
    end

    context ".js" do
      setup { Zaypay::PriceSetting.stubs(:new).returns @price_setting }
      should "set locale if params for country and language are present" do
        @price_setting.expects(:locale=)
        xhr :get, :new, :product_id => @product, :country => "NL", :language => 'nl'
      end
      should "not set locale when language or country are not present" do
        @price_setting.expects(:locale=).never
        xhr :get, :new, :product_id => @product, :country => "", :language => 'nl'
      end
    end
  end

  context "#create" do
    setup do
      @payment_methods = [{:charged_amount=>0.9E0, 
                          :eur_charged_amount=>0.9E0,
                          :payout=>0.42,
                          :name=>"sms", 
                          :payment_method_id=>2, 
                          :very_short_instructions=>"pay by sms", 
                          :formatted_amount=>"0,90", 
                          :very_short_instructions_with_amount=>"pay 0,90 by sms"}]
    end

    should "assign a product and price_setting" do
      @price_setting.expects(:create_payment).returns({:payment => {:id => 1}})
      post :create, :product_id => @product, :language => "nl", :country => 'NL', :payment_method => "2"
      assert_not_nil assigns(:product)
      assert_not_nil assigns(:ps)
    end

    context "#create_payment succeeds" do
      should "redirect to zaypay website" do
        @price_setting.expects(:create_payment).with(:payalogue_id => @product.payalogue_id, :purchase_id => Purchase.last.id + 1).returns({:payment => {:id => 1}})
        assert_difference "Purchase.count" do
          post :create, :product_id => @product, :language => "nl", :country => 'NL', :payment_method => "2"
        end
        assert_response :redirect
        assert_match /https:\/\/secure.zaypay.com/, @response.redirect_url
      end
    end

    context "#create_payment fails" do
      context "locale was not set" do
        should "redirect back to products" do
          @price_setting.expects(:create_payment).raises Zaypay::Error.new(:locale_not_set,)
          post :create, :product_id => @product, :language => "nl", :country => 'NL', :payment_method => "2"
          assert_response :redirect
          assert_redirected_to new_product_purchase_path(@product)
          assert_equal "There was an error with the country or language you provided", flash[:error]
        end
      end
      context "payment_method_id was not set" do
        should "redirect back to products#new and display flash msg" do
          @price_setting.expects(:create_payment).raises Zaypay::Error.new(:payment_method_id_not_set)
          post :create, :product_id => @product, :language => "nl", :country => 'NL', :payment_method => "2"
          assert_response :redirect
          assert_redirected_to new_product_purchase_path(@product)
          assert_equal "There was an error with the payment method you provided", flash[:error]
        end
      end
      context "due to other reasons" do
        should "redirect back to products#new and display flash msg" do
          @price_setting.expects(:create_payment).raises Zaypay::Error.new(:http_error)
          post :create, :product_id => @product, :language => "nl", :country => 'NL', :payment_method => "2"
          assert_response :redirect
          assert_redirected_to new_product_purchase_path(@product)
          assert_equal "Oops... Something went wrong, please try again", flash[:error]
        end
      end
    end
  end


  context "#report" do
    context "params[:payment_id] or params[:product_id] or params[:price_setting_id] is NOT present" do
      should "NOT find a purchase record" do
        Purchase.expects(:find_by_zaypay_payment_id).never
        get :report,  {:status => 'prepared',
                       :message => "This+payment+changed+state", 
                       :payment_id => "123456"}
      end
    end
    
    context "All necessary params are present" do
      should "Find a purchase record and call #update_status_by_valid_request" do
        purchase = Purchase.first
        Purchase.expects(:find).with('1').returns purchase
        purchase.expects(:update_status_by_valid_request)
        get :report,  {:price_setting_id => '222222', 
                       :status => 'prepared', 
                       :purchase_id => '1', 
                       :payalogue_id => '111111', 
                       :message => "This+payment+changed+state", 
                       :payment_id => "12345"}
      end
      
      should "not call update_status_by_valid_request when purchase cannot be found" do
        purchase = Purchase.first
        Purchase.expects(:find).with('20').returns nil
        purchase.expects(:update_status_by_valid_request).never
        get :report,  {:price_setting_id => '222222', 
                       :status => 'prepared', 
                       :purchase_id => '20', 
                       :payalogue_id => '111111', 
                       :message => "This+payment+changed+state", 
                       :payment_id => "12345"}
      end
    end

    should "return *ok* and don't render template" do
      get :report
      assert_equal "*ok*", @response.body
      assert_template false
    end
  end
end