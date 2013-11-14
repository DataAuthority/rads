require 'test_helper'

class RecordTest < ActiveSupport::TestCase

  should belong_to :creator
  should have_attached_file(:content)

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp

    @user = users(:non_admin)
    @user_record = records(:user)
    @user_record.content = @test_content
    @user_record.save
    @expected_path = [ @user.storage_path,  @user_record.id, @user_record.content_file_name ].join('/')

    @admin = users(:admin)
    @admin_record = records(:admin)
  end

  teardown do
    @user_record.content.destroy
    @user_record.destroy
    @admin_record.content.destroy
    @admin_record.destroy
  end

  should 'support find_by_md5 method' do
    assert_respond_to Record, 'find_by_md5'
    @trec = Record.find_by_md5(@expected_md5).take!
    assert_not_nil @trec
    assert_equal @user_record.id, @trec.id
  end
    
  should 'store content relative to user.storage_path' do
    assert_equal @expected_path, @user_record.content.path
    assert_equal @expected_md5, @user_record.content_fingerprint
  end

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, Record, [:index] )
      denied_abilities(nil, @user_record, [:show, :destroy])
      denied_abilities(nil, @admin_record, [:show, :destroy])
      denied_abilities(nil, Record.new, [:new, :create])
    end
  end #nil user
  
  context 'non_admin' do
    should 'pass ability profile' do
      allowed_abilities(@user, Record, [:index])
      allowed_abilities(@user, @user_record, [:index, :show, :destroy])
      denied_abilities(@user, @admin_record, [:index, :show, :destroy])
      allowed_abilities(@user, @user.records.build, [:new, :create])
    end
  end #non_admin

  context 'admin' do
    should 'pass ability profile' do      
      allowed_abilities(@admin, Record, [:index] )
      allowed_abilities(@admin, @user_record, [:show])
      allowed_abilities(@admin, @admin.records.build, [:new, :create])
      denied_abilities(@admin, @user.records.build, [:new, :create])
    end
  end #non_admin

end
