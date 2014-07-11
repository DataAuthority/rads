require 'test_helper'

class CartsControllerTest < ActionController::TestCase
  def self.test_cart_management()
    should 'get :show' do
      assert_not_nil @user
      assert_not_nil @user_cart_records
      assert @user_cart_records.length > 0, 'there should be some cart records'
      get :show
      assert_response :success
      assert_not_nil assigns(:cart_records)
      assigns(:cart_records).each do |cr|
        assert_equal @user.id, cr.user_id
      end
    end    

    should 'delete :destroy to empty their cart' do
      assert_not_nil @user
      assert_not_nil @user_cart_records
      cart_records_count = @user_cart_records.length
      assert cart_records_count > 0, 'user should have cart_records'
      assert CartRecord.count > cart_records_count
      assert_difference('CartRecord.count', -cart_records_count) do
        delete :destroy
      end
      assert_equal 0, @user.cart_records.count
      assert_redirected_to cart_url
    end
  end

  def self.test_destroy_records()
    should 'destroy any cart_record records that the user can destroy but leave records that the user cannot destroy, and produce an error' do
      assert_not_nil @user
      assert_not_nil @user_cart_records
      assert @user_cart_records.length > 0, 'there should be some cart_records'
      expected_cart_errors = {}
      @user_cart_records.each do |cr|
        assert File.exists?(cr.stored_record.content.path), 'file should exist before destroy'
        assert !cr.stored_record.is_destroyed?, 'record should not be destroyed'
        expected_cart_errors[cr.id] = @controller.current_ability.cannot?(:destroy, cr.stored_record.creator_id)
      end
      assert expected_cart_errors.keys.length > 0, 'there should be some cart_records that would produce errors with destroy'
      stored_records = @user.cart_records.collect {|r| r.stored_record}
      assert_equal stored_records.count, stored_records.uniq.count
      put :update, cart: {action: 'destroy_records'}
      assert_not_nil assigns(:cart_records)
      assigns(:cart_records).each do |cr|
        if expected_cart_errors[cr.id]
          assert !cr.stored_record.is_destroyed?, 'unauthorized record should not be destroyed'
          assert File.exists?(cr.stored_record.content.path), 'unauthorized record file should still exist after destroy'
          assert_not_nil assigns(:cart_errors)
          assert assigns(:cart_errors).has_key? cr.id
        else
          assert cr.stored_record.is_destroyed?, 'record should now be destroyed'
          assert !File.exists?(cr.stored_record.content.path), 'file should not exist after destroy'
        end
      end
    end
  end

  def self.data_producer_project_affiliation()
    should 'affiliate any cart_record records that a can :affiliate to the project but leave other records unaffiliated' do
      assert_not_nil @user
      assert_not_nil @project
      assert @project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should be a data_producer in the project'
      assert @user_cart_records.length > 0, 'there should be some cart_records'
      expected_cart_errors = {}
      expected_affiliated_records = @user_cart_records.length
      @user_cart_records.each do |cr|
        assert !@project.is_affiliated_record?(cr.stored_record), 'record should not be affiliated with the project'
        if @controller.current_ability.cannot?(:affiliate, cr.stored_record)
          expected_cart_errors[cr.id] = true
          expected_affiliated_records = expected_affiliated_records - 1;
        end
      end
      assert expected_affiliated_records > 0, 'there should be some cart_records that the user can affiliate'
      assert expected_cart_errors.keys.length > 0, 'there should be some cart_records that the user cannot affiliate'
      assert_difference('ProjectAffiliatedRecord.count', +expected_affiliated_records) do
        put :update, cart: {action: 'affiliate_to_project', project_id: @project.id}
      end
      assert_not_nil assigns(:cart_records)
      assigns(:cart_records).each do |cr|
        if expected_cart_errors[cr.id]
          assert_not_nil assigns(:cart_errors)
          assert assigns(:cart_errors).has_key? cr.id
          assert !@project.is_affiliated_record?(cr.stored_record), 'record should still not be affiliated with the project'
        else
          assert @project.is_affiliated_record?(cr.stored_record), 'record should now be affiliated with the project'
        end
      end
    end
  end

  def self.not_data_producer_project_affiliation()
    should 'not affiliate any records to the project' do
      assert_not_nil @user
      assert_not_nil @project
      assert !@project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should not be a data_producer in the project'
      assert_not_nil @user_cart_records
      assert @user_cart_records.length > 0, 'there should be some cart_records'
      @user.cart_records.each do |cr|
        assert !@project.is_affiliated_record?(cr.stored_record), 'record should not be affiliated with the project'
      end
      assert_no_difference('ProjectAffiliatedRecord.count') do
        put :update, cart: {action: 'affiliate_to_project', project_id: @project.id}
      end
      assert_not_nil assigns(:cart_records)
      assert_not_nil assigns(:cart_errors)
      assigns(:cart_records).each do |cr|
        assert assigns(:cart_errors).has_key? cr.id
      end
    end
  end

  def self.test_add_record_annotation()
    should 'create annotations for all cart_record records the user can show but skip records that the user cannot show' do
      assert_not_nil @user
      assert_not_nil @user_cart_records
      assert @user_cart_records.length > 0, 'there should be some cart_records'
      @user_cart_records.each do |cr|
        assert @controller.current_ability.can?(:show, cr.stored_record), 'there is a record in the users cart that they cannot show, which should not happen'
      end
      stored_records = @user_cart_records.collect {|r| r.stored_record}
      assert_equal stored_records.length, stored_records.uniq.length
      assert_difference('Annotation.count', stored_records.length) do
        put :update, cart: {action: 'add_record_annotation', term: 'Foo', context: 'Bar'}
      end
      assert_not_nil assigns(:cart_records)
      assigns(:cart_records).each do |cr|
        assert cr.stored_record.annotations.where(term: 'Foo', context: 'Bar', creator_id: @user.id).exists?, 'record should now be annotated by the user'
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

  context "RepositoryUser" do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @user_cart_records = @user.cart_records.all
      @user_cart_records.each do |cr|
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
    test_add_record_annotation
  end

  context "Admin" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @user_cart_records = @user.cart_records.all
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
    test_add_record_annotation
  end

  context "ProjectUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @user_cart_records = @user.cart_records.all
      @user_cart_records.each do |cr|
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
    test_add_record_annotation
  end

  context "CoreUser" do
    setup do
      @real_user = users(:non_admin)
      authenticate_existing_user(@real_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @user_cart_records = @user.cart_records.all
      @user_cart_records.each do |cr|
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
    test_add_record_annotation
  end

  context "Admin RepositoryUser with no membership in a project" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @user_cart_records = @user.cart_records.all
      @project = projects(:membership_test)
    end

    not_data_producer_project_affiliation
  end

  context "Admin RepositoryUser with membership in a project but no roles" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
      @project.project_memberships.create(user_id: @user.id)
    end

    not_data_producer_project_affiliation
  end

  context "Admin RepositoryUser with the administrator role in the project" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)      
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id, is_administrator: true)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Admin RepositoryUser with data_producer role in the project" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
      @project.project_memberships.create(user_id: @user.id, is_data_producer: true)
      @user.cart_records.create(record_id: records(:pm_producer_unaffiliated_record).id)
    end

    data_producer_project_affiliation
  end

  context "Admin RepositoryUser with data_consumer role in the project" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Admin RepositoryUser with data_manager role in the project" do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id, is_data_manager: true)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Non-Admin RepositoryUser with no membership in a project" do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Non-Admin RepositoryUser with membership in a project but no roles" do
    setup do
      @user = users(:p_m_member)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Non-Admin RepositoryUser with the administrator role in the project" do
    setup do
      @user = users(:p_m_administrator)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Non-Admin RepositoryUser with data_producer role in the project" do
    setup do
      @user = users(:p_m_producer)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    data_producer_project_affiliation
  end

  context "Non-Admin RepositoryUser with data_consumer role in the project" do
    setup do
      @user = users(:p_m_consumer)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "Non-Admin RepositoryUser with data_manager role in the project" do
    setup do
      @user = users(:p_m_dmanager)
      authenticate_existing_user(@user, true)
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "CoreUser with no membership in a project" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "CoreUser with membership in a project but no roles" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "CoreUser with data_producer role in the project" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    data_producer_project_affiliation
  end

  context "CoreUser with data_consumer role in the project" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "ProjectUser with no membership in the project" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "ProjectUser with membership in a project but no roles" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

  context "ProjectUser with data_producer role in the project" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @user_cart_records = @user.cart_records.all
    end

    data_producer_project_affiliation
  end

  context "ProjectUser with data_consumer role in the project" do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @project = projects(:membership_test)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @user_cart_records = @user.cart_records.all
    end

    not_data_producer_project_affiliation
  end

end
