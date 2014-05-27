require 'test_helper'

class CartRecordsControllerTest < ActionController::TestCase

  def self.test_cart_management()
    should 'get :index' do
      get :index
      assert_response :success
      assert_not_nil assigns(:cart_records)
      assert assigns(:cart_records).include? @user_cart_record
    end

    should 'create a cart_record with their own record' do
      assert_difference('CartRecord.count') do
        post :create, cart_record: { record_id: @user_record.id }
      end
      assert_redirected_to cart_records_url
      assert_not_nil assigns(:cart_record)
      assert_equal @user.id, assigns(:cart_record).user_id
      assert_eqaual @user_record.id, assigns(:cart_record).record_id
    end

    should 'destroy their cart_record' do
      assert_difference('CartRecord.count',-1) do
        delete :destroy, id: @user_cart_record
      end
      assert_redirected_to cart_records_url
    end

    should 'not destroy a cart_record belonging to another user' do
      assert_no_difference('CartRecord.count') do
        delete :destroy, id: @other_user_cart_record
      end
      assert_redirected_to root_path
    end
  end

  def self.test_add_readable_record()
    should 'create a cart_record with a record that they can read but do not own' do
      allowed_abilities(@user, @readable_record, [:read])
      assert @readable_record.creator_id != @user.id, 'user should not own readable_record'
      assert_difference('CartRecord.count') do
        post :create, cart_record: { record_id: @readable_record.id }
      end
      assert_redirected_to cart_records_url
      assert_not_nil assigns(:cart_record)
      assert_equal @user.id, assigns(:cart_record).user_id
      assert_eqaual @readable_record.id, assigns(:cart_record).record_id
    end
  end

  def self.test_unreadable_record()
    should 'not create a cart_record with a record that they cannot read' do
      denied_abilities(@user, @unreadable_record, [:read])
      assert_no_difference('CartRecord.count') do
        post :create, cart_record: { record_id: @unreadable_record.id }
      end
      assert_redirected_to root_path
    end
  end

  setup do
    @cart_record = cart_records(:user)
  end

  should 'not have show, edit, update routes' do
    assert_raises(ActionController::UrlGenerationError) {
      get :show, id: @cart_record
    }
    assert_raises(ActionController::UrlGenerationError) {
      get :edit, id: @cart_record
    }
    assert_raises(ActionController::UrlGenerationError) {
      patch :update, id: @cart_record
    }
  end

  context "unauthenticated user" do
    should 'not get :index' do
      get :index
      assert_redirected_to sessions_new_url(:target => cart_records_url)
    end
  end

  context "authenticated RepositoryUser" do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @user_record = records(:user)
      @user_cart_record = cart_records(:user)
      @other_user_cart_record = cart_records(:other_user)
      @readable_record = records(:project_one_affiliated_project_user)
      @unreadable_record = records(:core_user)
    end
    test_cart_management
    test_add_readable_record
    test_unreadable_record
  end

  context "authenticated Admin" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @user_record = records(:admin)
      @user_cart_record = cart_records(:admin)
      @other_user_cart_record = cart_records(:user)
      @readable_record = records(:project_one_affiliated_project_user)
    end
    test_cart_management
    test_add_readable_record
  end

  context "authenticated ProjectUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id

      @user_record = records(:project_user)
      @user_cart_record = cart_records(:project_user)
      @other_user_cart_record = cart_records(:user)

      #project_users are not members of projects, so they cannot read any record but their own
      @unreadable_record = records(:core_user)
    end
    test_cart_management
    test_unreadable_record
  end

  context "authenticated CoreUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id

      @user_record = records(:core_user)
      @user_cart_record = cart_records(:core_user)
      @other_user_cart_record = cart_records(:user)
      @readable_record = records(:project_two_affiliated)
      @unreadable_record = records(:project_user)
    end
    test_cart_management
    test_add_readable_record
    test_unreadable_record
  end
end
