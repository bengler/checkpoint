require 'activerecord_helper'

describe Account do

  let(:account) { Account.new(:provider => :facebook, :uid => 'abc123', :realm_id => 1, :identity_id => 2, :token => 'token', :secret => 'secret') }

  describe 'required attributes' do
    [:uid, :identity_id, :provider, :realm_id].each do |attribute|
      specify "#{attribute} can't be nil" do
        account.attributes = {attribute => nil}
        account.should_not be_valid
      end

      specify "#{attribute} can't be an empty string" do
        account.attributes = {attribute => ''}
        account.should_not be_valid
      end
    end

    specify "uid can contain the usual for usernames" do
      account.uid = 'a-bc_123.go'
      account.should be_valid
    end

    it "rejects unknown providers" do
      account.provider = :unknown_provider
      account.should_not be_valid
    end
  end

  describe "#credentials_for" do
    it "finds keys for a specific identity and provider" do
      keys = Account.create!(:provider => :facebook, :uid => 'abc123', :realm_id => 1, :identity_id => 17, :token => 'token', :secret => 'secret')
      identity = stub(:id => 17)
      Account.credentials_for(identity, :facebook).should eq(keys)
    end

    it "ignores keys where token/secret are missing" do
      Account.create!(:provider => :facebook, :uid => 'abc123', :realm_id => 1, :identity_id => 17)
      identity = stub(:id => 17)
      Account.credentials_for(identity, :facebook).should be_nil
    end
  end

end
