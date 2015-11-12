require 'spec_helper'

describe IdentityIp do

  it 'logs unique ips' do
    IdentityIp.declare!('192.168.1.1', 1)
    IdentityIp.declare!('192.168.1.2', 1)
    IdentityIp.declare!('192.168.1.2', 1)
    IdentityIp.count.should eq 2
  end

  it 'logs unique sessions' do
    IdentityIp.declare!('192.168.1.1', 1)
    IdentityIp.declare!('192.168.1.1', 2)
    IdentityIp.declare!('192.168.1.1', 2)
    IdentityIp.count.should eq 2
  end

  it 'defines an ip that has originated more than two unique sessions within a short time frame as hot' do
    IdentityIp.create!(:address => '192.168.1.1', :identity_id => 90, :created_at => Time.now-24*60*60)
    IdentityIp.declare!('192.168.1.1', 1)
    IdentityIp.hot?('192.168.1.1').should be_falsey
    IdentityIp.declare!('192.168.1.2', 1) # A new session from a different ip
    IdentityIp.hot?('192.168.1.1').should be_falsey
    IdentityIp.declare!('192.168.1.1', 2)
    IdentityIp.hot?('192.168.1.1').should be_truthy
  end

end
