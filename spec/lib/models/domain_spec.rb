require 'spec_helper'

describe Domain do

  let :realm do
    Realm.create!(:label => "area51")
  end

  it "assigns itself as primary domain if it is the first domain registered to the realm" do
    domain = Domain.create!(:realm => realm, :name => "example.org")
    realm.reload.primary_domain_id.should eq domain.id
    Domain.create!(:realm => realm, :name => "example.com")
    realm.reload.primary_domain_id.should eq domain.id
  end

  it 'accepts IP addresses' do
    Domain.new(:realm => realm, :name => '127.0.0.1').valid?.should == true
  end

  describe '#resolve_from_host_name' do
    it 'resolves domain from name' do
      domain = Domain.create!(:realm => realm, :name => 'example.com')
      Domain.resolve_from_host_name('example.com').should == domain
    end

    it 'resolves domain from IP addresses' do
      domain = Domain.create!(:realm => realm, :name => '127.0.0.1')
      Domain.resolve_from_host_name('127.0.0.1').should == domain
    end

    it 'resolves domain from host by resolving it into domain IP' do
      domain = Domain.create!(:realm => realm, :name => '127.0.0.1')
      Domain.resolve_from_host_name('localhost').should == domain
    end
  end

end