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
      if user.is_administrator?
        can :manage, User, :type => nil
        can [:read, :edit, :update, :destroy, :switch_to], RepositoryUser
        can :read, Record
        can [:index, :show, :update, :destroy, :switch_to], CoreUser
        cannot :destroy, User, :id => user.id
      else
        can :read, User, :type => nil
        can :read, RepositoryUser
        can [:edit, :update, :destroy], RepositoryUser, :id => user.id
      end

      if user.type == 'RepositoryUser'
        can :read, Core
        can [:new, :create], [Core, Project]
        can :switch_to, CoreUser, :core_id => user.cores.collect{|m| m.id}
        can :manage, CoreMembership, :core_id => user.cores.collect{|m| m.id}
        cannot :destroy, CoreMembership, :repository_user_id => user.id
      end
      if user.type == 'CoreUser'
        can :read, Core, id: user.core_id
      end
    end
  end
end
