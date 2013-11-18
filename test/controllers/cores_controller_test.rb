require 'test_helper'

class CoresControllerTest < ActionController::TestCase
  setup do
    @core = cores(:one)
  end

  context 'Not Authenticated User' do
  end #Not Authenticated User

  #switch to user
  context 'Non-RepositoryUser' do
  end #Non-RepositoryUser

  context 'RepositoryUser' do
  end #RepositoryUser
end
