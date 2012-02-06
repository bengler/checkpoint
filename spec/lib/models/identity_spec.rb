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

    it "can read throught a cache" do
      identity = someone
      result = Identity.cached_find_by_id(identity.id)
      result.should eq identity
      attributes = result.attributes
      attributes[:god] = true
      $memcached.set(result.cache_key, attributes.to_json)
      from_cache = Identity.cached_find_by_id(identity.id)
      from_cache.god?.should be_true
    end

    it "can read a collection through a cache" do
      identities = (1..20).map { Identity.create!(:realm => realm) }
      from_db = Identity.cached_find_all_by_id(identities[0..10].map(&:id))
      from_db.map(&:id).should eq from_db[0..10].map(&:id)
      # Spoof all cached identities as gods
      from_db.each do |identity|
        attributes = identity.attributes.merge({'god' => true})        
        $memcached.set(identity.cache_key, attributes.to_json)
      end
      from_db_and_cache = Identity.cached_find_all_by_id(identities[0..20].map(&:id))
      # Check all gods
      from_db_and_cache[0..10].map(&:god).inject(true){|r, e| r && e}.should be_true
      # Check all muggles
      from_db_and_cache[11..19].map(&:god).inject(true){|r, e| r && !e}.should be_true
    end

    it "can retrieve a user from a session_key" do 
      me = someone
      session = Session.create!(:identity => me)
      Identity.find_by_session_key(session.key).should eq me
      # Again from cache
      Identity.find_by_session_key(session.key).should eq me
    end

    it "can find identities not seen for a while" do
      (0..9).each do |age|
        Identity.create!(:realm => realm, :last_seen_at => Time.now.to_date - age)
      end
      Identity.not_seen_for_more_than_days(20).size.should eq 0
      Identity.not_seen_for_more_than_days(9).size.should eq 0
      Identity.not_seen_for_more_than_days(8).size.should eq 1
      Identity.not_seen_for_more_than_days(1).size.should eq 8
      Identity.not_seen_for_more_than_days(0).size.should eq 9
    end

    describe "#root?" do
      let(:root) { Realm.create!(:label => 'root') }

      it "has root" do
        he = Identity.new(:realm => root, :god => true)
        he.should be_root
      end

      it "is not root if just a regular guy" do
        he = Identity.new(:realm => root, :god => false)
        he.should_not be_root
      end

      it "is not root if good in a different realm" do
        he = Identity.new(:realm => realm, :god => true)
        he.should_not be_root
      end

    end

  end
end
