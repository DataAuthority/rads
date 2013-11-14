class Ability
  include CanCan::Ability

  def initialize(user)
    if user.nil?
      can [:new, :create], RepositoryUser
    elsif !user.is_enabled?
      can :show, RepositoryUser, :id => user.id
    elsif user.is_administrator?
      can :manage, User, :type => nil
      can [:read, :edit, :update, :destroy, :switch_to], RepositoryUser
      can :read, Record
      can :manage, Record, :creator_id => user.id
      cannot :destroy, User, :id => user.id
    else
      can :read, User, :type => nil
      can :read, RepositoryUser
      can :manage, Record, :creator_id => user.id
      can [:edit, :update, :destroy], RepositoryUser, :id => user.id
    end
  end
end
