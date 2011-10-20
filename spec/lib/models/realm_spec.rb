require 'spec_helper'

describe Realm do
  it "grabs all the keys" do
    keys = {
      :twitter => {:consumer_key => 'twitter_key', :consumer_secret => 'twitter_secret'},
      :facebook => {:client_id => 'facebook_id', :client_secret => 'facebook_secret'}
    }

    realm = Realm.create!(:label => 'realm', :service_keys => keys.to_yaml)
    realm.external_service_keys.should eq(keys)
  end

  it "delivers api keys for twitter" do
    keys = { :twitter => {:consumer_key => 'twitter_key', :consumer_secret => 'twitter_secret'} }

    realm = Realm.create!(:label => 'realm', :service_keys => keys.to_yaml)
    keys = realm.keys_for(:twitter)
    keys.consumer_key.should eq('twitter_key')
    keys.consumer_secret.should eq('twitter_secret')
  end

  it "delivers api keys for facebook" do
    keys = {:facebook => {:client_id => 'facebook_app_id', :client_secret => 'facebook_secret'}}

    realm = Realm.create!(:label => 'realm', :service_keys => keys.to_yaml)
    keys = realm.keys_for(:facebook)
    keys.client_id.should eq('facebook_app_id')
    keys.client_secret.should eq('facebook_secret')
  end

  describe "#find_by_url" do
    let(:realm) { Realm.create!(:label => 'realm') }

    context "with just a root zone" do
      before :each do
        Domain.create(:realm => realm, :name => 'example.org')
      end

      it "finds domain immediately if it matches exactly" do
        Realm.find_by_url('example.org').should eq(realm)
      end

      it "finds domain if it matches with a subdomain" do
        Realm.find_by_url('for.example.org').should eq(realm)
      end

      it "fails to match on partial domains" do
        Realm.find_by_url('forexample.org').should be_nil
      end

      it "fails to find with extra tld" do
        Realm.find_by_url('www.example.org.com').should be_nil
      end

    end

    context "with a qualified subdomain" do
      before :each do
        Domain.create(:realm => realm, :name => 'for.example.org')
      end

      it "finds an exact match" do
        Realm.find_by_url('for.example.org').should eq(realm)
      end

      it "finds a wide match" do
        Realm.find_by_url('www.for.example.org').should eq(realm)
      end

      it "does not match on a partial selection" do
        Realm.find_by_url('example.org').should be_nil
      end
    end
  end
end
