require 'uri'
require 'simpleidn'
require 'timeout'
require 'socket'

# Represents either a DNS domain name or an IP address.
class Domain < ActiveRecord::Base

  belongs_to :realm
  has_one :primary_realm,
    :class_name => 'Realm',
    :foreign_key => :primary_domain_id,
    :dependent => :nullify

  after_save :ensure_primary_domain
  
  validates :name, :presence => {}, :uniqueness => {}
  validates_each :name do |record, attr, name|
    unless Domain.valid_name?(name)
      record.errors.add(attr, :invalid_name)
    end
  end

  class << self
    # Finds domain matching a host name.
    def resolve_from_host_name(host_name)
      domain = Domain.where(:name => host_name).first
      if not domain and not ip_address?(host_name)
        begin
          timeout(4) do
            begin
              ips = TCPSocket.gethostbyname(SimpleIDN.to_ascii(host_name))
              ips.select! { |s| s.is_a?(String) && ip_address?(s) }
              domain = Domain.where(:name => ips).first
            rescue SocketError => e
              logger.error("Socket error resolving #{host_name}")
            end
          end
        rescue Timeout::Error => e
          logger.error("Timeout resolving #{host_name} via DNS")
        end
      end
      domain
    end

    # Check that name is RFC-compliant with regard to length and permitted characters.
    def valid_name?(name)
      name &&
        (ip_address?(name) ||
          (name.length <= RFC_NAME_LIMIT &&
          name.split('.').map(&:length).max <= RFC_NAME_LABEL_LIMIT &&
          SimpleIDN.to_ascii(name) =~ RFC_NAME_PATTERN))
    end

    # Is this an IPv4 address?
    def ip_address?(string)
      string =~ IP_ADDRESS_PATTERN
    end
  end

  def name=(name)
    if name
      super(name.gsub(/\s/, '').downcase)
    else
      super(nil)
    end
  end

  private

    IP_ADDRESS_PATTERN = /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/

    RFC_NAME_PATTERN = /\A[a-z0-9][a-z\.0-9-]+\z/ui.freeze
    RFC_NAME_LIMIT = 253
    RFC_NAME_LABEL_LIMIT = 63

    def ensure_primary_domain
      if self.realm and not self.realm.primary_domain
        self.realm.primary_domain = self
        self.realm.save!
      end
      nil
    end

end
