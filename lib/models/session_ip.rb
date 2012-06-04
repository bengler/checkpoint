# Keeps track of which ip-addresses a certain session has been acessed from
# to support fraud detection.

class SessionIp < ActiveRecord::Base
  def self.declare!(address, key)
    attributes = {:address => address, :key => key}
    session_ip = SessionIp.where(attributes).first
    session_ip ||= SessionIp.create!(attributes)
    session_ip
  end

  # A hot address is an address that has originated a great number of 
  # new sessions recently. options[:minutes] specifies the time frame,
  # and options[:count] specifies the number of sessions that can 
  # be created within that time frame before the address is "hot".

  def self.hot?(address, options = {})
    minutes = options[:minutes] || 30
    count = options[:count] || 2
    new_sessions = self.where(:address => address).where("created_at > ?", Time.now-(minutes*60)).count
    (new_sessions > count)
  end
end