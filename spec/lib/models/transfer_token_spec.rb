require 'spec_helper'

describe TransferToken do
  it 'generates unique tokens with unique secrets' do
    (1..100).to_a.map {
      TransferToken.generate("blorp").token
    }.uniq.length.should == 100

    (1..100).to_a.map {
      TransferToken.generate("blorp").secret
    }.uniq.length.should == 100
  end

  it 'is persistent' do
    token = TransferToken.generate('blorp')
    found = TransferToken.find(token.token)
    found.token.should == token.token
    found.referrer.should == token.referrer
    found.secret.should == token.secret
  end

  it 'can sign stuff with secret' do
    token = TransferToken.generate('blorp')
    
    token.sign_with_secret("Howdy pardner").should == Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::SHA256.new, token.secret, "Howdy pardner")).strip
  end

  it 'validates referrer by host only' do
    token = TransferToken.generate('http://example.com/howdy/pardner')
    %w(http https).each do |scheme|
      token.valid_referrer?("#{scheme}://example.com").should == true
      token.valid_referrer?("#{scheme}://example.com/").should == true
      token.valid_referrer?("#{scheme}://example.com/howdy").should == true
      token.valid_referrer?("#{scheme}://example.com/doody").should == true

      token.valid_referrer?("#{scheme}://EXAMPLE.COM").should == true
      token.valid_referrer?("#{scheme}://EXAMPLE.COM/").should == true
      token.valid_referrer?("#{scheme}://EXAMPLE.COM/howdy").should == true
      token.valid_referrer?("#{scheme}://EXAMPLE.COM/doody").should == true

      token.valid_referrer?("#{scheme}://example.org").should == false
      token.valid_referrer?("#{scheme}://example.org/").should == false
      token.valid_referrer?("#{scheme}://example.org/howdy").should == false
      token.valid_referrer?("#{scheme}://example.org/howdy/pardner").should == false
      token.valid_referrer?("#{scheme}://example.org/doody").should == false
    end
  end
end
