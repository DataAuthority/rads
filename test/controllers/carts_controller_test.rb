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
    should 'destroy all cart_record records if all cart_records are tied to records that the user owns' do
      assert @user.cart_records.count > 0, 'there should be some cart_records'
      @user.cart_records.each do |cr|
        if @user.id == cr.stored_record.creator_id
          assert File.exists?(cr.stored_record.content.path), 'file should exist before destroy'
          assert !cr.stored_record.is_destroyed?, 'record should not be destroyed'
        else
          cr.destroy
        end
      end
      stored_records = @user.cart_records.collect {|r| r.stored_record}
      assert_equal stored_records.count, stored_records.uniq.count
      put :update, cart: {action: 'destroy_records'}
      assert_not_nil assigns(:cart_records)
      assigns(:cart_records).each do |cr|
        assert cr.stored_record.is_destroyed?, 'record should now be destroyed'
        assert !File.exists?(cr.stored_record.content.path), 'file should not exist after destroy'
      end
    end

    should 'not destroy any records if one or more cart_records are tied to records that the user does not own' do
      assert @readable_record_cart_record.stored_record.creator_id != @user.id, 'user should not own readable_record'
      assert @user.cart_records.count > 0, 'there should be some cart_records'
      @user.cart_records.each do |cr|
        assert File.exists?(cr.stored_record.content.path), "file #{cr.stored_record.content.path} should exist before destroy"
        assert !cr.stored_record.is_destroyed?, 'record should not be destroyed'
      end
      put :update, cart: {action: 'destroy_records'}
      assert_not_nil assigns(:cart_records)
      assigns(:cart_records).each do |cr|
        assert File.exists?(cr.stored_record.content.path), 'file should still exist after destroy'
        assert !cr.stored_record.is_destroyed?, 'record should still not be destroyed'
      end
    end
  end

  def self.test_project_affiliation()
    should 'affiliate all cart_record records to a project if all cart_records are tied to records that the user owns and the user can affiliate to the project' do
      user_cart_records = 0
      @user.cart_records.each do |cr|
        if @user.id == cr.stored_record.creator_id
          assert !@project.is_affiliated_record?(cr.stored_record), 'record should not be affiliated with the project'
          user_cart_records += 1
        else
          cr.destroy
        end
      end
      assert user_cart_records > 0, 'there should be some cart_records'
      assert_difference('ProjectAffiliatedRecord.count', +user_cart_records) do
        put :update, cart: {action: 'affiliate_to_project', project_id: @project.id}
      end
    end

    should 'not affliate any records to a project if one or more cart_records are tied to records that the user does not own' do
      assert @readable_record_cart_record.stored_record.creator_id != @user.id, 'user should not own readable_record'
      user_cart_records = 0
      @user.cart_records.each do |cr|
        if @project.is_affiliated_record?(cr.stored_record)
          @project.project_affiliated_records.where(record_id: cr.record_id).destroy_all
        end
        assert !@project.is_affiliated_record?(cr.stored_record), 'record should not be affiliated with the project'
        user_cart_records += 1
      end

      assert user_cart_records > 0, 'there should be some cart_records'
      assert_no_difference('ProjectAffiliatedRecord.count') do
        put :update, cart: {action: 'affiliate_to_project', project_id: @project.id}
      end
      @user.cart_records.each do |cr|
        assert !@project.is_affiliated_record?(cr.stored_record), 'record should still not be affiliated with the project'
      end
    end

    should 'not affliate any records to a project if the user cannot affiliate to the project' do
      assert !@other_project.is_member?(@user), 'user should not be a member'
      user_cart_records = 0
      @user.cart_records.each do |cr|
        if @user.id == cr.stored_record.creator_id
          assert_equal @user.id, cr.stored_record.creator_id
          assert !@other_project.is_affiliated_record?(cr.stored_record), 'record should not be affiliated with the project'
          user_cart_records += 1
        else
          cr.destroy
        end
      end
      assert user_cart_records > 0, 'there should be some cart_records'
      assert_no_difference('ProjectAffiliatedRecord.count') do
        put :update, cart: {action: 'affiliate_to_project', project_id: @other_project.id}
      end
    end
  end

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
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
      @readable_record_cart_record = @user.cart_records.create(record_id: records(:project_one_affiliated_project_user).id)
      @user.cart_records.each do |cr|
        cr.stored_record.content = @test_content
        cr.stored_record.save
      end
      @project = @user.projects.first
      @other_project = projects(:two)      
    end

    teardown do
      @user.cart_records.each do |cr|
        if cr.stored_record
          cr.stored_record.content.destroy
          cr.stored_record.destroy
        end        
      end
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
      @readable_record_cart_record = @user.cart_records.create(record_id: records(:project_one_affiliated_project_user).id)
      @user.cart_records.each do |cr|
        cr.stored_record.content = @test_content
        cr.stored_record.save
      end
      @project = @user.projects.first
      @other_project = projects(:one)
    end

    teardown do
      @user.cart_records.each do |cr|
        if cr.stored_record
          cr.stored_record.content.destroy
          cr.stored_record.destroy
        end
      end
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
      @readable_record_cart_record = @user.cart_records.create(record_id: records(:core_user).id)
      @user.cart_records.each do |cr|
        cr.stored_record.content = @test_content
        cr.stored_record.save
      end
    end

    teardown do
      @user.cart_records.each do |cr|
        if cr.stored_record
          cr.stored_record.content.destroy
          cr.stored_record.destroy
        end
      end
    end

    test_cart_management
    test_destroy_records
  end

  context "authenticated CoreUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @user_cart_record = cart_records(:core_user)
      @readable_record_cart_record = @user.cart_records.create(record_id: records(:project_two_affiliated).id)
      @user.cart_records.each do |cr|
        cr.stored_record.content = @test_content
        cr.stored_record.save
      end
      @project = @user.projects.first
      @other_project = projects(:one)
    end

    teardown do
      @user.cart_records.each do |cr|
        if cr.stored_record
          cr.stored_record.content.destroy
          cr.stored_record.destroy
        end
      end
    end

    test_cart_management
    test_destroy_records
    test_project_affiliation
  end
end
