require 'test_helper'

class PurchaseByCustomerFlowTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:one)
    @price_setting = dutch_price_setting_mock
    Zaypay::PriceSetting.stubs(:new).returns @price_setting
  end

  context "customer on main page" do
    should "see a button to products path" do
      get root_path
      assert_response :success
      assert_template "index"
      assert_select "a#products_index_button"
    end
  end

  context "customer on products page" do
    should "see name, description for products" do
      get products_path
      assert_response :success
      assert_template "index"
      assert_select "tr#product_1 td.product_name", @product.name
      assert_select "tr#product_1 td a[href=?]", new_product_purchase_path(@product)
      assert_select "tr#product_1 td.product_description", @product.description
    end
  end

  context "customer clicks on a product" do
    context "ip_country of customer is configured" do
      setup do
        @configured_country = {:country=>{:code=>"NL", :name=>"Netherlands"}, :locale=>{:country=>"NL", :language=>"nl"}}
      end
      should "be presented with a form with languages, countries and payment_methods" do
        @price_setting.stubs(:ip_country_is_configured?).returns @configured_country
        get new_product_purchase_path(@product)
        assert_response :success
        assert_template "new"
        assert_select "div#language_selection"
        assert_select "div#country_selection"
        assert_select "div#payment_method_selection"
        assert_select "div#submit_wrapper"
      end
    end
    context "ip_country of customer is NOT configured" do
      setup do
        # do some customization to our standard dutch_price_setting_mock
        @price_setting.stubs(:locale).returns nil
        @price_setting.stubs(:ip_country_is_configured?).returns nil
      end
      should "hide select_tag for payment_methods and submit button" do
        @price_setting.stubs(:ip_country_is_configured?).returns nil
        get new_product_purchase_path(@product)
        assert_select "div#payment_method_selection", false
        assert_select "div#submit_wrapper", false
      end
    end
  end

  context "customer does not submit language OR country OR payment_method" do
    should "not create a purchase object and redirect back to products page" do
      assert_no_difference "Purchase.count" do
        post product_purchases_path(@product), {:language => "nl", :country => '', :payment_method => ""}
      end
      assert_response :redirect
      assert_redirected_to new_product_purchase_path(@product)
      assert_equal "You did not select a country.<br/>You did not select a payment method.", flash[:error]
    end
  end

  context "customer submits all necessary info" do
    should "create a payment and update the purchase if the incoming report is valid" do
      assert_difference "Purchase.count" do
        @price_setting.expects(:create_payment).returns({:payment => {:id => '123456'}})
        post product_purchases_path(@product), {:language => "nl", :country => 'NL', :payment_method => "2"}
        assert_equal @product.id, Purchase.last.product_id
        assert_equal 123456, Purchase.last.zaypay_payment_id
      end
      purchase_id = Purchase.last.id
      assert_response :redirect
      assert_match /https:\/\/secure.zaypay.com/, @response.redirect_url

      @price_setting.expects(:show_payment).returns({:payment => {:id => 12345, :status => "prepared"}})
      get '/report', {:price_setting_id => '222222', 
                      :status => 'prepared', 
                      :purchase_id => purchase_id, 
                      :payalogue_id => '111111', 
                      :message => "This+payment+changed+state", 
                      :payment_id => "123456"}
      assert_equal "prepared", Purchase.find(purchase_id).status
      
      @price_setting.expects(:show_payment).returns({:payment => {:id => 12345, :status => "in_progress"}})
      get '/report', {:price_setting_id => '222222', 
                      :status => 'in_progress', 
                      :purchase_id => purchase_id, 
                      :payalogue_id => '111111', 
                      :message => "This+payment+changed+state", 
                      :payment_id => "123456"}
      assert_equal "in_progress", Purchase.find(purchase_id).status
      
      @price_setting.expects(:show_payment).returns({:payment => {:id => 12345, :status => "paid"}})
      get '/report', {:price_setting_id => '222222', 
                      :status => 'paid', 
                      :purchase_id => purchase_id, 
                      :payalogue_id => '111111', 
                      :message => "This+payment+changed+state", 
                      :payment_id => "123456"}
      assert_equal "paid", Purchase.find(purchase_id).status
    end
  end
end