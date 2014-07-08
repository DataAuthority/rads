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
      can :affiliate_record_with, Project, :project_memberships => {:user_id => user.id, :is_data_producer => true}
      can [:create, :destroy], ProjectAffiliatedRecord, :project => {:project_memberships => {:user_id => user.id, :is_data_producer => true}}, :affiliated_record => {:creator_id => user.id}
      can :read, Project
      can :index, Annotation
      can [:new, :create], Annotation, :creator_id => user.id, :annotated_record => {:creator_id => user.id }
      can [:new, :create], Annotation, :creator_id => user.id, :annotated_record => {:projects => {:project_memberships => {:user_id => user.id}}}
      can :destroy, Annotation, :creator_id => user.id
      can :manage, Record, :creator_id => user.id
      cannot :destroy, Record, :is_destroyed => true
      can :read, Record, :project_affiliated_records => {:project => {:project_memberships => {:user_id => user.id}}}
      can :download, Record, :project_affiliated_records => {:project => {:project_memberships => {:user_id => user.id, :is_data_consumer => true}}}
      can :read, ProjectMembership, :project => {:project_memberships => {:user => {:id => user.id}}}
      can :manage, CartRecord, :user_id => user.id, :stored_record => {:project_affiliated_records => {:project => {:project_memberships => {:user_id => user.id}}}}
      can :manage, CartRecord, :user_id => user.id, :stored_record => {:creator_id => user.id }
      can :update, Project, :project_memberships => {:user_id => user.id, :is_data_producer => true}

      if user.is_administrator?
        can :manage, User, :type => nil
        can [:read, :edit, :update, :destroy, :switch_to], [RepositoryUser, CoreUser, ProjectUser]
        can :read, [AuditedActivity]
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
        can [:edit, :update, :update_attributes], Project, :project_memberships => {:user_id => user.id, :is_administrator => true}
        can [:destroy], ProjectAffiliatedRecord, :project => {:project_memberships => {:user_id => user.id, :is_administrator => true}}
        can :switch_to, CoreUser, :core => {:core_memberships => { :repository_user_id => user.id }}
        can :switch_to, ProjectUser, :project => {:project_memberships => {:user_id => user.id, :is_data_manager => true}}
        can [:create, :read, :edit, :update, :new, :destroy], CoreMembership, :core => {:core_memberships => { :repository_user => {:id => user.id }}}
        cannot :create, CoreMembership, :repository_user_id => user.id
        can [:edit, :update, :new, :create, :destroy], ProjectMembership, :project_id => user.project_memberships.where(is_administrator: true).collect{|m| m.project_id}.append(nil)
        # this one is made difficult by the use of an authorize :create in the projects_controller
        cannot :destroy, CoreMembership, :repository_user_id => user.id
        cannot [:edit, :update, :destroy], ProjectMembership, :user_id => user.id
        cannot :create, ProjectMembership, is_administrator: true, user: {type: 'CoreUser'}
        cannot :create, ProjectMembership, is_administrator: true, user: {type: 'ProjectUser'}
        cannot :create, ProjectMembership, is_data_manager: true, user: {type: 'CoreUser'}
        cannot :create, ProjectMembership, is_data_manager: true, user: {type: 'ProjectUser'}
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
