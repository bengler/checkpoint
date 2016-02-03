# Keeps track of which ip-addresses a certain identity has been acessing
# the service from. Used for fraud detection. Only creates an entry when
# an identity is seen for the first time on a specific ip.

class IdentityIp < ActiveRecord::Base
  def self.declare!(address, identity_id)
    attributes = {:address => address, :identity_id => identity_id}
    record = self.find_by(attributes)
    record ||= self.create!(attributes)
    record
  end

  # A hot address is an address that has seen a great number of 
  # new identities recently. options[:minutes] specifies the time frame,
  # and options[:count] specifies the number of sessions that can 
  # be created within that time frame before the address is "hot".

  def self.hot?(address, options = {})
    minutes = options[:minutes] || 30
    count = options[:count] || 2
    new_sessions = self.where(:address => address).where("created_at > ?", Time.now-(minutes*60)).count
    (new_sessions >= count)
  end
end