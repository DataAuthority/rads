require 'test_helper'

class CartsControllerTest < ActionController::TestCase
  def self.test_cart_management()
    should 'get :show' do
      get :show
      assert_response :success
      assert_not_nil assigns(:cart_records)
      assert assigns(:cart_records).include? @user_cart_record
      assigns(:cart_records).each do |cr|
        assert_equal @user.id, cr.user_id
      end
    end    

    should 'delete :destroy to empty their cart' do
      cart_records_count = @user.cart_records.count
      assert cart_records_count > 0, 'user should have cart_records'
      assert CartRecord.count > cart_records_count
      assert_difference('CartRecord.count', -cart_records_count) do
        delete :destroy
      end
      assert_redirected_to cart_url
    end
  end

  def self.test_destroy_records()
  end

  def self.test_project_affiliation()
  end

  context "unauthenticated user" do
    should 'not get :show' do
      get :show
      assert_redirected_to sessions_new_url(:target => cart_url)
    end
    should 'not delete :empty' do
      assert_no_difference('CartRecord.count') do
        delete :destroy
      end
      assert_redirected_to sessions_new_url(:target => cart_url)
    end
  end

  context "authenticated RepositoryUser" do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @user_cart_record = cart_records(:user)
    end
    test_cart_management
    test_destroy_records
    test_project_affiliation
  end

  context "authenticated Admin" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @user_cart_record = cart_records(:admin)
    end
    test_cart_management
    test_destroy_records
    test_project_affiliation
  end

  context "authenticated ProjectUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @user_cart_record = cart_records(:project_user)
    end
    test_cart_management
    test_destroy_records
    test_project_affiliation
  end

  context "authenticated CoreUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @user_cart_record = cart_records(:core_user)
    end
    test_cart_management
  end
end
