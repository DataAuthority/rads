require 'test_helper'

class AgentTest < ActiveSupport::TestCase

  def self.non_repository_user_tests
    should 'pass ability profile' do
      assert_not_nil @user
      assert_not_nil @agent

      denied_abilities(@user, Agent.new, [:index, :new, :create])
      denied_abilities(@user, @agent, [:show, :edit, :update, :destroy])
    end
  end

  should belong_to :creator
  should validate_presence_of :name
  should validate_presence_of :creator_id

  context 'API' do
    setup do
      @agent = agents(:non_admin_agent)
    end

    should 'support is_disabled?' do
      assert_respond_to @agent, 'is_disabled?'
      assert !@agent.is_disabled?, 'agent should not be disabled'
      @agent.is_disabled = true
      assert @agent.is_disabled?, 'agent should now be disabled'
    end
  end

  context 'NonAdmin RepositoryUser' do
    setup do
      @user = users(:non_admin)
      @agent = agents(:non_admin_agent)
      @other_user_agent = agents(:admin_agent)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, Agent.new, [:index, :new])
      allowed_abilities(@user, @user.agents.build, [:create])
      allowed_abilities(@user, @agent, [:show, :edit, :update, :destroy])
      allowed_abilities(@user, @other_user_agent, [:show])
      denied_abilities(@user, @other_user_agent, [:edit, :update, :destroy])
      denied_abilities(@user, @other_user_agent.creator.agents.build, [:create])
    end
  end

  context 'Admin RepositoryUser' do
    setup do
      @user = users(:admin)
      @agent = agents(:admin_agent)
      @other_user_agent = agents(:non_admin_agent)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, Agent.new, [:index, :new])
      allowed_abilities(@user, @user.agents.build, [:create])
      allowed_abilities(@user, @agent, [:show, :edit, :update, :destroy])
      allowed_abilities(@user, @other_user_agent, [:show, :edit, :update, :destroy])
      denied_abilities(@user, @other_user_agent.creator.agents.build, [:create])
    end
  end

  context 'CoreUser' do
    setup do
      @user = users(:core_user)
      @agent = agents(:non_admin_agent)
    end

    non_repository_user_tests
  end

  context 'ProjectUser' do
    setup do
      @user = users(:project_user)
      @agent = agents(:non_admin_agent)
    end

    non_repository_user_tests
  end

end
