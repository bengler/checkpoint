require 'openssl'
require 'digest/sha1'
require 'uri'

class TransferToken

  attr_reader :token, :secret, :referrer

  def initialize(token, secret, referrer)
    @token, @secret, @referrer = token, secret, referrer
  end

  def self.generate(referrer)
    token = new(
      SecureRandom.random_number(2 ** 256).to_s(36).strip,
      SecureRandom.random_number(2 ** 256).to_s(36).strip, referrer)
    token.save
    token
  end

  def self.find(token)
    data = $memcached.get(cache_key(token))
    data &&= Marshal.load(data)
    if data.is_a?(Hash)
      return TransferToken.new(token, data[:secret], data[:referrer])
    end
  end

  def valid_referrer?(referrer)
    host_from_referrer(@referrer) == host_from_referrer(referrer)
  end

  def save
    $memcached.set(TransferToken.cache_key(@token), Marshal.dump(
      :referrer => @referrer,
      :secret => @secret
    ), 5.minutes)
  end

  def sign_with_secret(data)
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::SHA256.new, @secret, data)).strip
  end

  private

    def self.cache_key(value)
      "transfer_token:#{value}"
    end

    def host_from_referrer(referrer)
      uri = URI.parse(referrer) rescue nil
      if uri
        uri.host
      end
    end

end