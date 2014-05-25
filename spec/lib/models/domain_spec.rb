# encoding: utf-8

require 'spec_helper'

describe Domain do

  let :realm do
    Realm.create!(label: "area51")
  end

  it "assigns itself as primary domain if it is the first domain registered to the realm" do
    domain = Domain.create!(realm: realm, name: "example.org")
    realm.reload.primary_domain_id.should eq domain.id
    Domain.create!(realm: realm, name: "example.com")
    realm.reload.primary_domain_id.should eq domain.id
  end

  describe 'Validation' do
    it 'accepts IP addresses' do
      Domain.new(realm: realm, name: '127.0.0.1').valid?.should == true
    end

    it 'accepts valid names' do
      Domain.new(realm: realm, name: 'foo.example.com').valid?.should == true
    end

    it 'rejects non-IDN names' do
      domain = Domain.new(realm: realm, name: "frøhø")
      domain.valid?.should == false
      domain.errors[:name][0].should =~ /must_be_idn/  # FIXME: No i18n yet
    end

    it 'rejects names that are too long' do
      domain = Domain.new(realm: realm, name: 'x' * 254)
      domain.valid?.should == false
      domain.errors[:name][0].should =~ /dns_name_is_too_long/  # FIXME: No i18n yet
    end

    it 'rejects names that contain labels that are too long' do
      domain = Domain.new(realm: realm, name: 'xxx.' + 'x' * 64)
      domain.valid?.should == false
      domain.errors[:name][0].should =~ /dns_name_has_too_long_label/  # FIXME: No i18n yet
    end
  end

  describe '#resolve_from_host_name' do
    context 'domain is a name' do
      let! :domain do
        Domain.create!(realm: realm, name: 'example.com')
      end

      it 'matches exact name' do
        expect(Domain.resolve_from_host_name('example.com')).to eq domain
      end
    end

    context 'domain is IP address' do
      let! :domain do
        Domain.create!(realm: realm, name: '127.0.0.1')
      end

      it 'matches exact IP address' do
        expect(Domain.resolve_from_host_name('127.0.0.1')).to eq domain
      end

      it 'matches by resolving its IP' do
        expect(Domain.resolve_from_host_name('localhost')).to eq domain
      end
    end

    context 'domain is name with wildcards' do
      let! :domain do
        Domain.create!(realm: realm, name: '*.example.com')
      end

      it 'matches name' do
        expect(Domain.resolve_from_host_name('foo.example.com')).to eq domain
      end

      it 'matches strictly (* requires at least one character)' do
        expect(Domain.resolve_from_host_name('example.com')).to_not eq domain
      end
    end
  end

end