require 'ostruct'
class Realm < ActiveRecord::Base

  has_many :accounts
  has_many :identities

  validates_presence_of :label, :api_key
  validates_uniqueness_of :label

  def external_service_keys
    keys = YAML.load(self.service_keys)
    raise "Missing or malformed configuration for <Realm:#{id} #{label}>" unless keys
    keys
  end

  def keys_for(provider)
    OpenStruct.new(external_service_keys.fetch(provider))
  end

end
