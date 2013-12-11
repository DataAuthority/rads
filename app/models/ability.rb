class Ability
  include CanCan::Ability

  def initialize(user)
    if user.nil?
      can [:new, :create], RepositoryUser
    elsif !user.is_enabled?
      can :show, RepositoryUser, :id => user.id
    else
      can :read, Project
      can :manage, Record, :creator_id => user.id
      can :read, Record, :id => user.projects.collect{|p| p.project_affiliated_records.collect{|m| m.record_id}}
      can [:index, :show, :new, :destroy], ProjectAffiliatedRecord, :project_id => user.projects.collect{|p| p.id}
      can [:create], ProjectAffiliatedRecord, :project_id => user.projects.collect{|p| p.id}, :record_id => user.records.collect{|r| r.id}
      can :read, ProjectMembership, :project_id => user.projects.collect{|m| m.id}

      if user.is_administrator?
        can :manage, User, :type => nil
        can [:read, :edit, :update, :destroy, :switch_to], [RepositoryUser, CoreUser, ProjectUser]
        can :read, Record
        cannot :destroy, User, :id => user.id
      else
        can :read, RepositoryUser
        can [:edit, :update, :destroy], RepositoryUser, :id => user.id
      end

      if user.type == 'RepositoryUser'
        can :read, Core
        can [:new, :create], [Core, Project]
        can [:edit, :update], Project, :id => user.projects.collect{|m| m.id}
        can :switch_to, CoreUser, :core_id => user.cores.collect{|m| m.id}
        can :switch_to, ProjectUser, :project_id => user.projects.collect{|m| m.id}
        can :manage, CoreMembership, :core_id => user.cores.collect{|m| m.id}
        can [:new, :create, :destroy], ProjectMembership, :project_id => user.projects.collect{|m| m.id}
        cannot :destroy, CoreMembership, :repository_user_id => user.id
        cannot :destroy, ProjectMembership, :user_id => user.id
      end
      if user.type == 'CoreUser'
        can :read, Core, id: user.core_id
      end      
    end
  end
end
