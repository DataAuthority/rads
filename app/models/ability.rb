class Ability
  include CanCan::Ability

  def initialize(user)
    if user.nil?
      can [:new, :create], RepositoryUser
    elsif !user.is_enabled?
      can :show, RepositoryUser, :id => user.id
    else
      can [:index, :show], ProjectAffiliatedRecord, :project => {:project_memberships => {:user_id => user.id}}
      can :new, ProjectAffiliatedRecord, :project => {:project_memberships => {:user_id => user.id, :is_data_producer => true}}
      can [:create, :destroy], ProjectAffiliatedRecord, :project => {:project_memberships => {:user_id => user.id, :is_data_producer => true}}, :affiliated_record => {:creator_id => user.id}
      can :read, Project
      can :manage, Record, :creator_id => user.id
      cannot :destroy, Record, :is_destroyed => true
      can :read, Record, :id => user.projects.collect{|p| p.project_affiliated_records.collect{|m| m.record_id}}.flatten
      can :download, Record, :project_affiliated_records => {:project => {:project_memberships => {:user_id => user.id, :is_data_consumer => true}}}
      can :read, ProjectMembership, :project_id => user.projects.collect{|m| m.id}
      can :manage, CartRecord, :user_id => user.id, :record_id => user.projects.collect{|p| p.project_affiliated_records.collect{|m| m.record_id}}.flatten + user.records.collect{|r| r.id }
      can :update, Project, :id => user.project_memberships.where(is_data_producer: true).collect{|m| m.project_id}
 
      if user.is_administrator?
        can :manage, User, :type => nil
        can [:read, :edit, :update, :destroy, :switch_to], [RepositoryUser, CoreUser, ProjectUser]
        can :read, [Record,AuditedActivity]
        can :manage, CartRecord, :user_id => user.id
        cannot :destroy, User, :id => user.id
        cannot [:edit, :update, :destroy], User, :id => user.acting_on_behalf_of
      else
        can :read, RepositoryUser
        can [:edit, :update, :destroy], RepositoryUser, :id => user.id
      end

      if user.type == 'RepositoryUser'
        can :read, Core
        can [:new, :create], [Core, Project]
        cannot :edit, Project
        can [:edit, :update, :update_attributes], Project, :id => user.project_memberships.where(is_administrator: true).collect{|m| m.project_id}
        can [:destroy], ProjectAffiliatedRecord, :project => {:project_memberships => {:user_id => user.id, :is_administrator => true}}
        can :switch_to, CoreUser, :core_id => user.cores.collect{|m| m.id}
        can :switch_to, ProjectUser, :project_id => user.project_memberships.where(is_data_manager: true).collect{|m| m.project_id}
        can :manage, CoreMembership, :core_id => user.cores.collect{|m| m.id}
        can [:edit, :update, :new, :create, :destroy], ProjectMembership, :project_id => user.project_memberships.where(is_administrator: true).collect{|m| m.project_id}.append(nil)
        cannot :destroy, CoreMembership, :repository_user_id => user.id
        cannot [:edit, :update, :destroy], ProjectMembership, :user_id => user.id
        cannot :create, ProjectMembership, is_administrator: true, user_id: User.all.reject{|u| u.type == 'RepositoryUser'}.collect{|u| u.id}
        cannot :create, ProjectMembership, is_data_manager: true, user_id: User.all.reject{|u| u.type == 'RepositoryUser'}.collect{|u| u.id}
      end
      if user.type == 'CoreUser'
        can :read, Core, id: user.core_id
        cannot [:edit, :update_attributes], Project
      end
      if user.type == 'ProjectUser'
        cannot [:edit, :update_attributes], Project
      end
    end
  end
end
