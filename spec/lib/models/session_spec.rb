require 'spec_helper'

describe Session do
  it "Calculates a cache key" do
    Session.cache_key("pling").should eq "session:pling"
  end

  it "can create random keys" do
    (1..10000).map{ Session.random_key }.uniq.size.should eq 10000
  end

  it "generates a random key for new sessions" do
    session = Session.create!(:identity_id => 10)
    session.key.should =~ /[0-9a-z]+/    
  end

  it "Retrieves identities from keys in the database and caches them" do
    pending "Caching removed due to confusion about varnish issues" do
      session = Session.create!(:identity_id => 10)
      Session.identity_id_for_session(session.key).should eq 10
      $memcached.get(session.cache_key).should eq '10'
    end
  end

  it "Reads identites from the cache if a key exists" do
    pending "Caching removed due to confusion about varnish issues" do
      hash = 'secretkeystuffs'
      $memcached.set(Session.cache_key(hash), '10')
      Session.identity_id_for_session(hash).should eq 10
    end
  end

  it "Deletes itself from cache when destroyed" do
    session = Session.create!(:identity_id => 10)
    Session.identity_id_for_session(session.key).should eq 10
    session.destroy
    Session.identity_id_for_session(session.key).should be_nil
  end
end
