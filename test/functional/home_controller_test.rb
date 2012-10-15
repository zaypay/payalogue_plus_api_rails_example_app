require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  context "#index" do
    should "should be successful" do
      get :index
      assert_response :success
    end
  
    should "should render index" do
      get :index
      assert_template "index"
    end
  end
end
