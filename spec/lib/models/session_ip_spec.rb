require 'spec_helper'

describe Realm do

  it 'logs unique ips' do
    SessionIp.declare!('192.168.1.1', 'a session')
    SessionIp.declare!('192.168.1.2', 'a session')
    SessionIp.declare!('192.168.1.2', 'a session')
    SessionIp.count.should eq 2
  end

  it 'logs unique sessions' do
    SessionIp.declare!('192.168.1.1', 'a session')
    SessionIp.declare!('192.168.1.1', 'another session')
    SessionIp.declare!('192.168.1.1', 'another session')
    SessionIp.count.should eq 2
  end

  it 'defines an ip that has originated more than two unique sessions within a short time frame as hot' do
    SessionIp.create!(:address => '192.168.1.1', :key => 'an old session', :created_at => Time.now-24*60*60)
    SessionIp.declare!('192.168.1.1', 'a session')
    SessionIp.hot?('192.168.1.1').should be_false
    SessionIp.declare!('192.168.1.1', 'a second session')
    SessionIp.hot?('192.168.1.1').should be_false
    SessionIp.declare!('192.168.1.2', 'a fresh session on another ip')
    SessionIp.hot?('192.168.1.1').should be_false
    SessionIp.declare!('192.168.1.1', 'a third second session')
    SessionIp.hot?('192.168.1.1').should be_true
  end

end