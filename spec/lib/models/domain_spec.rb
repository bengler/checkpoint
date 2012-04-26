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

end