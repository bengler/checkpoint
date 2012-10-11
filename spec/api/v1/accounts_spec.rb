require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Accounts" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let! :realm do
    Realm.create!(:label => "area51")
  end

  let! :domain do
    Domain.create!(:name => 'example.com', :realm => realm)
  end

  let! :identity do 
    Identity.create!(:realm => realm)
  end

  let! :account do
    account = Account.create!(
      :identity => identity,
      :realm => realm,
      :provider => 'twitter',
      :uid => '1',
      :token => 'token',
      :secret => 'secret',
      :nickname => 'nickname',
      :name => 'name',
      :profile_url => 'profile_url',
      :image_url => 'image_url')
    identity.primary_account = account
    identity.save!
    account
  end

  let :god do
    Identity.create!(:god => true, :realm => realm)
  end

  let :me_session do
    Session.create!(:identity => identity).key
  end

  let :god_session do
    Session.create!(:identity => god).key
  end

  describe "GET /identities/me/accounts/:provider" do
    it "hands me my keys" do
      get "/identities/me/accounts/twitter", :session => me_session
      result = JSON.parse(last_response.body)['account']
      result['identity_id'].should eq identity.id
      result['uid'].should eq '1'
      result['token'].should eq 'token'
      result['secret'].should eq 'secret'
      result['provider'].should eq 'twitter'
    end

    it "refuses to hand me the keys for someone else" do
      get "/identities/#{god.id}/accounts/twitter", :session => me_session
      last_response.status.should eq 403
    end

    it "hands me anyones key if I'm god" do
      get "/identities/#{identity.id}/accounts/twitter", :session => god_session
      result = JSON.parse(last_response.body)['account']
      result['uid'].should eq '1'
      result['token'].should eq 'token'
      result['secret'].should eq 'secret'
    end
  end

  describe "POST /identities/:id/accounts/:provider/:uid" do

    context 'when account does not exist' do
      let :accountless_identity do
        Identity.create!(:realm => realm)
      end

      let :session do
        Session.create!(:identity => accountless_identity)
      end

      it 'denies accounts created by non-god users' do
        post "/identities/#{accountless_identity.id}/accounts/twitter/666",
          {:nickname => 'bob', :session => session.key},
          {'HTTP_HOST' => realm.primary_domain_name}
        last_response.status.should eq 403
        accountless_identity.reload
        account = accountless_identity.accounts.first
        account.should == nil
      end

      it 'gods may create an account' do
        post "/identities/#{accountless_identity.id}/accounts/twitter/666",
          {:nickname => 'bob', :session => god_session},
          {'HTTP_HOST' => realm.primary_domain_name}
        accountless_identity.reload
        account = accountless_identity.accounts.first
        account.should_not == nil
        account.nickname.should == 'bob'
      end
    end

    context 'when account already exists' do
      it 'updates the account' do
        post "/identities/#{identity.id}/accounts/twitter/1", {:nickname => 'bob', :session => god_session},
          {'HTTP_HOST' => realm.primary_domain_name}
        account.reload
        account.nickname.should == 'bob'
      end
    end

  end

end
