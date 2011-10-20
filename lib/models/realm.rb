require 'ostruct'
class Realm < ActiveRecord::Base

  has_many :accounts
  has_many :identities
  has_many :domains

  validates_uniqueness_of :label, :allow_nil => false

  def external_service_keys
    keys = YAML.load(self.service_keys)
    raise "Missing or malformed configuration for #<Realm:#{id} #{label}>" unless keys
    keys
  end

  def keys_for(provider)
    OpenStruct.new(external_service_keys.fetch(provider))
  end

end
