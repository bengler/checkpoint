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
end
