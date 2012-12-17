require 'spec_helper'

describe Callback do
  it "can be retrieved by path" do
    Callback.create!(:path => "a.b.c", :url => "http://example.org/a/b/c")
    Callback.create!(:path => "a.b", :url => "http://example.org/a/b")
    Callback.create!(:path => "b.c.d", :url => "http://example.org/b/c/d")
    Callback.urls_for_path('a.b.c').should eq ["http://example.org/a/b/c", "http://example.org/a/b"]
    Callback.urls_for_path('z').should eq []
  end

  it "can be retrieved by realm" do
    Callback.create!(:path => "a.b.c", :url => "http://example.org/a/b/c")
    Callback.create!(:path => "a.b", :url => "http://example.org/a/b")
    Callback.create!(:path => "b.c.d", :url => "http://example.org/b/c/d")
    Callback.of_realm('a').count.should eq 2
    realm_b = Realm.create!(:label => 'b')
    Callback.of_realm(realm_b).count.should eq 1
  end

  context "callbacks" do
    around :each do |example|
      VCR.turned_off do
        example.run
      end
    end

    before :each do
      # A callback that accepts everything
      stub_http_request(:any, "http://yay.org/").
        with(:body => "{\"method\":\"create\",\"identity\":7,\"uid\":\"post.blog:a.b.c.d.e\"}",
          :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
         to_return(:status => 200, :body => '{"allow":true}',
           :headers => {'Content-Type' => 'application/json'})

      # A callback that accepts nothing
      stub_http_request(:any, "http://nay.org/").
        with(:body => "{\"method\":\"create\",\"identity\":7,\"uid\":\"post.blog:a.b.c.d.e\"}",
          :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
         to_return(:status => 200, :body => '{"allow":false, "reason": "You are not worthy"}',
           :headers => {'Content-Type' => 'application/json'})
    end

    it "forwards the parameters to the callback and processes the positive response" do
      Callback.create!(:path => "a.b.z", :url => "http://nay.org") # irrelevant, should not trigger
      Callback.create!(:path => "a.b.c", :url => "http://yay.org")
      allowed, url, reason = Callback.allow?(:method => :create, :identity => 7, :uid => "post.blog:a.b.c.d.e")
      allowed.should be_true
      url.should be_nil
      reason.should be_nil
    end

    it "forwards the parameters to the callback and processes the negative response" do
      Callback.create!(:path => "a.b.c", :url => "http://nay.org")
      Callback.create!(:path => "a.b.c.d", :url => "http://yay.org") # will be overridden
      allowed, url, reason = Callback.allow?(:method => :create, :identity => 7, :uid => "post.blog:a.b.c.d.e")
      allowed.should be_false
      url.should eq "http://nay.org"
      reason.should eq "You are not worthy"
    end
  end

end
