require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @create_params = { project: { name: 'new_project', description: 'new project for testing' } }
  end

  context 'Not Authenticated' do
    should_not_get :index
    should_not_get :new

    should "not show project" do
      get :show, id: @project
      assert_redirected_to sessions_new_url(:target => project_url(@project))
    end

    should "not create project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
      end
      assert_redirected_to sessions_new_url(:target => projects_url(@create_params))
    end
  end #Not Authenticated

  context 'CoreUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @puppet = users(:core_user)
      session[:switch_to_user_id] = @puppet.id
      @member_project = @puppet.projects.first
      @unaffiliated_records = @puppet.records.to_a
    end

    should "not get :new" do
      get :new
      assert_redirected_to root_path()
    end

    should "get index" do
      get :index
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:projects)
    end

    should "get show" do
      get :show, id: @project
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end

    should "not create a project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
      end
      assert_equal @puppet.id, @controller.current_user.id
      assert_redirected_to root_path()
    end

    should 'be able to affiliate multiple records with a project if they are a member' do
      assert @member_project.is_member?(@puppet), 'core_user should be a member of member_project'
      @unaffiliated_records.each do |should_be_affiliated|
        assert !@member_project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @member_project.id }"
      end
      assert_difference('ProjectAffiliatedRecord.count', @unaffiliated_records.length) do
        patch :update, id: @member_project, project: {
          project_affiliated_records_attributes: @unaffiliated_records.map {|r|
            { record_id: r.id }
          }
        }
      end
      assert_redirected_to project_path(@member_project)
      t_p = Project.find(@member_project.id)
      @unaffiliated_records.each do |should_be_affiliated|
        assert t_p.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should be affiliated with #{ t_p.id }"
      end
    end

    should 'not update project name or description even if they are a member' do
      orig_name = @member_project.name
      orig_description = @member_project.description
      new_name = 'evil_core_project'
      new_description = 'this is evil cores project now'
      assert @member_project.is_member?(@puppet), 'core_user should be a member of member_project'
      patch :update, id: @member_project, project: {
        name: new_name,
        description: new_description
      }
      assert_response 403
      t_p = Project.find(@member_project.id)
      assert_equal orig_name, @member_project.name
      assert_equal orig_description, @member_project.description
    end

    should 'not affiliate records with a  project if they are not a member' do
      assert !@project.is_member?(@puppet), 'core_user should not be a member of project'
      @unaffiliated_records.each do |should_be_affiliated|
        assert !@project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      assert_no_difference('ProjectAffiliatedRecord.count') do
        patch :update, id: @project, project: {
          project_affiliated_records_attributes: @unaffiliated_records.map {|r|
            { record_id: r.id }
          }
        }
      end
      assert_redirected_to root_path()
      t_p = Project.find(@project.id)
      @unaffiliated_records.each do |should_be_affiliated|
        assert !t_p.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should still not be affiliated with #{ t_p.id }"
      end
    end
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
      @other_project = projects(:two)
    end

    should "not get :new" do
      get :new
      assert_redirected_to root_path()
    end

    should "get index" do
      get :index
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:projects)
    end

    should "get show on its own project" do
      get :show, id: @project
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end

    should "get show on other project" do
      get :show, id: @other_project
      assert_equal @puppet.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @other_project.id, assigns(:project).id
    end

    should "not create a project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
      end
      assert_equal @puppet.id, @controller.current_user.id
      assert_redirected_to root_path()
    end
  end #ProjectUser

  context 'RepositoryUser' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:projects)
    end

    should "get new" do
      get :new
      assert_response :success
      assert_not_nil assigns(:project)
      assert_not_nil assigns(:unaffiliated_records)
      assert !assigns(:unaffiliated_records).empty?, 'should have unaffiliated_records'
      assert assigns(:unaffiliated_records).include?(records(:user_unaffiliated)), 'should include user_unaffiliated in unaffiliated_records'
      assert !assigns(:unaffiliated_records).include?(records(:admin)), 'should not include another users record in unaffiliated_records'
    end

    should "get show" do
      get :show, id: @project
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end

    should "create a project, and be listed as the creator" do
      assert_difference('Project.count') do
        assert_difference('ProjectUser.count') do
          post :create, @create_params
          assert_not_nil assigns(:project)
          assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
      assert @t_project.project_memberships.where(user_id: @user.id).exists?, 'creator should have a new project_membership for the project'
    end

    should "create a project with project_affiliated_records_attributes" do
      [ records(:user), records(:user_unaffiliated) ].each do |should_be_affiliated|
        assert !@project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      @create_params[:project][:project_affiliated_records_attributes] = [
                                                     { record_id: records(:user).id },
                                                     { record_id: records(:user_unaffiliated).id },
                                                     ]
      assert_difference('Project.count') do
        assert_difference('ProjectUser.count') do
          assert_difference('ProjectAffiliatedRecord.count', 2) do
            post :create, @create_params
            assert_not_nil assigns(:project)
            assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
          end
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
      assert @t_project.project_memberships.where(user_id: @user.id).exists?, 'creator should have a new project_membership for the project'
      [ records(:user), records(:user_unaffiliated) ].each do |should_be_affiliated|
        assert @t_project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should be affiliated with #{ @t_project.id }"
      end
    end
  end #RepositoryUser

  context 'ProjectMember' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)      
    end

    should 'be able to edit the project' do
      assert @project.is_member?(@user), 'user should be a member of the project'
      get :edit, id: @project
      assert_response :success
      assert_not_nil assigns(:unaffiliated_records)
      assert !assigns(:unaffiliated_records).empty?, 'should have unaffiliated_records'
      assert assigns(:unaffiliated_records).include?(records(:user_unaffiliated)), 'should include user_unaffiliated in unaffiliated_records'
      assert !assigns(:unaffiliated_records).include?(records(:project_one_affiliated)), 'should not include affiliated records in unaffiliated_records'
      assert !assigns(:unaffiliated_records).include?(records(:admin)), 'should not include another users record in unaffiliated_records'
    end

    should 'be able to update the project' do
      new_description = "NEW DESCRIPTION"
      patch :update, id: @project, project: {description: new_description }
      assert_redirected_to project_path(@project)
      t_p = Project.find(@project.id)
      assert_equal new_description, t_p.description
    end

     should 'be able to update the project to add project_affiliated_records_attributes' do
      [ records(:user), records(:user_unaffiliated) ].each do |should_be_affiliated|
        assert !@project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      assert_difference('ProjectAffiliatedRecord.count', 2) do
        patch :update, id: @project, project: {project_affiliated_records_attributes: [ 
                                                                            { record_id: records(:user).id },
                                                                            { record_id: records(:user_unaffiliated).id }                                                                        ]}
      end
      assert_redirected_to project_path(@project)
      t_p = Project.find(@project.id)
      [ records(:user), records(:user_unaffiliated) ].each do |should_be_affiliated|
        assert t_p.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should be affiliated with #{ t_p.id }"
      end
    end
  end #ProjectMember

  context 'NonMember' do
    setup do
      @user = users(:dm)
      authenticate_existing_user(@user, true)      
    end

    should 'not be able to edit the project' do
      assert !@project.is_member?(@user), 'user should not be a member of the project'
      get :edit, id: @project
      assert_redirected_to root_path()
    end

    should 'not be able to update the project' do
      new_description = "NEW DESCRIPTION"
      old_description = @project.description
      patch :update, id: @project, project: {description: new_description }
      assert_redirected_to root_path()
      t_p = Project.find(@project.id)
      assert_equal old_description, @project.description
    end
  end
end
