require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  context "#index" do
    should "be success" do
      get :index
      assert_response :success
      assert_template "index"
    end
    
    should "assign @products" do
      get :index
      assert_not_nil assigns(:products)
    end
  end
end
