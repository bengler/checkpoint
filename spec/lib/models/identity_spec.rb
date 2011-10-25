require 'spec_helper'

describe Identity do
  context "updating session manager" do
    let :realm do
      Realm.create!(:label => 'realm')
    end

    let :someone do
      Identity.create!(:realm => realm)
    end

    let :account1 do
      Account.create!(:identity => someone,
        :realm => realm,
        :uid => '1',
        :provider => 'twitter',
        :name => "account1")
    end

    let :account2 do 
      Account.create!(:identity => someone,
        :realm => realm,
        :uid => '1',
        :provider => 'facebook',
        :name => 'account2')
    end

    it "updates the identity record when primary account is switched or modified" do
      someone.primary_account = account1
      someone.save!
      JSON.parse(SessionManager.redis.get("identity:#{someone.id}"))['identity']['profile']['name'].should eq 'account1'
      someone.primary_account = account2
      someone.save!
      JSON.parse(SessionManager.redis.get("identity:#{someone.id}"))['identity']['profile']['name'].should eq 'account2'
      account2.name = "bingo"
      account2.save!
      JSON.parse(SessionManager.redis.get("identity:#{someone.id}"))['identity']['profile']['name'].should eq 'bingo'
      account1.name = "bananas"
      account1.save!
      JSON.parse(SessionManager.redis.get("identity:#{someone.id}"))['identity']['profile']['name'].should eq 'bingo'
    end

  end
end
