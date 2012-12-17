require 'spec_helper'

describe Protector do
  it "can be retrieved by path" do
    Protector.create!(:path => "a.b.c", :callback_url => "http://example.org/a/b/c")
    Protector.create!(:path => "a.b", :callback_url => "http://example.org/a/b")
    Protector.create!(:path => "b.c.d", :callback_url => "http://example.org/b/c/d")
    Protector.callbacks('a.b.c').should eq ["http://example.org/a/b/c", "http://example.org/a/b"]
    Protector.callbacks('z').should eq []
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
      Protector.create!(:path => "a.b.z", :callback_url => "http://nay.org") # irrelevant, should not trigger
      Protector.create!(:path => "a.b.c", :callback_url => "http://yay.org")
      allowed, url, reason = Protector.allow?(:method => :create, :identity => 7, :uid => "post.blog:a.b.c.d.e")
      allowed.should be_true
      url.should be_nil
      reason.should be_nil
    end

    it "forwards the parameters to the callback and processes the negative response" do
      Protector.create!(:path => "a.b.c", :callback_url => "http://nay.org")
      Protector.create!(:path => "a.b.c.d", :callback_url => "http://yay.org") # will be overridden
      allowed, url, reason = Protector.allow?(:method => :create, :identity => 7, :uid => "post.blog:a.b.c.d.e")
      allowed.should be_false
      url.should eq "http://nay.org"
      reason.should eq "You are not worthy"
    end
  end

end
