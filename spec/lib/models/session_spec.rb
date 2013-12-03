require 'spec_helper'

describe Session do

  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
  end

  let :identity do 
    Identity.create!(:realm => realm)
  end

  it "Calculates a cache key" do
    Session.cache_key("pling").should eq "session:pling"
  end

  it "can create random keys" do
    (1..10000).map{ Session.random_key }.uniq.size.should eq 10000
  end

  it "generates a random key for new sessions" do
    session = Session.create!(:identity => identity)
    session.key.should =~ /[0-9a-z]+/    
  end

  it "Retrieves identities from keys in the database and caches them" do
    session = Session.create!(:identity => identity)
    Session.identity_id_for_session(session.key).should eq identity.id
    $memcached.get(session.cache_key).should eq identity.id
  end

  it "Reads identites from the cache if a key exists" do
    hash = 'secretkeystuffs'
    $memcached.set(Session.cache_key(hash), identity.id.to_s)
    Session.identity_id_for_session(hash).should eq identity.id
  end

  it "Deletes itself from cache when destroyed" do
    session = Session.create!(:identity => identity)
    Session.identity_id_for_session(session.key).should eq identity.id
    session.destroy
    Session.identity_id_for_session(session.key).should be_nil
  end

  it "has a unique key" do
    Session.create!(:identity => identity, :key => "abcde")
    lambda {
      Session.create!(:identity => identity, :key => "abcde")
    }.should raise_error ActiveRecord::RecordNotUnique
  end

end
