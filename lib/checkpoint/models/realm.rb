require 'ostruct'

class Realm < ActiveRecord::Base

  has_many :accounts
  has_many :identities
  has_many :domains
  belongs_to :primary_domain, :class_name => "Domain"

  serialize :service_keys

  validates_uniqueness_of :label, :allow_nil => false
  validates_each :label do |record, attr, value|
    record.errors.add(attr, "Realm name 'current' is reserved") if value == 'current'
  end

  class << self
    def environment_overrides
      @environment_overrides ||= load_environment_overrides
    end

    def load_environment_overrides
      file_name = File.expand_path('../../../../config/overrides.yml', __FILE__)
      config = load_environment_overrides_from(file_name)
      if config.any?
        LOGGER.info "Loaded environment configuration overrides from #{file_name}"
      end
      config
    end

    def load_environment_overrides_from(file_name, env = ENV['RACK_ENV'])
      config = HashWithIndifferentAccess.new
      begin
        config.merge!((YAML.load(File.open(file_name, 'r:utf-8')) || {}).fetch(env, {}))
      rescue Errno::ENOENT
        # Ignore
      end
      config
    end
  end

  def self.find_by_url(url)
    host = url =~ /:\/\// ? URI.parse(url).host : url

    Domain.search_strings_for_hostname(host) do |host|
      cache_key = Domain.realm_cache_key_for_host(host)
      if (cached = $memcached.get(cache_key))
        parsed = Yajl::Parser.parse(cached)
        parsed['service_keys'] = parsed['service_keys'].to_yaml
        return Realm.instantiate(parsed)
      else
        realm = Domain.resolve_from_host_name(host).try(:realm)
        if realm
          $memcached.set(cache_key, realm.attributes.to_json)
          return realm
        end
      end
    end

    nil
  end

  def primary_domain_name
    name = self.class.environment_overrides.fetch(self.label, {})[:primary_domain]
    name ||= self.primary_domain.try(:name)
  end

  def god_sessions
    Session.where("sessions.identity_id in (select id from identities where god and realm_id = ?)", id)
  end

  def external_service_keys
    keys = HashWithIndifferentAccess.new
    if self.service_keys.present?
      if self.service_keys.is_a?(String)
        if (yaml = YAML.load(self.service_keys))
          keys.merge!(yaml)
        else
          raise "Missing or malformed configuration for #<Realm:#{id} #{label}>"
        end
      else
        keys.merge!(self.service_keys)
      end
    end
    keys.merge!(self.class.environment_overrides.fetch(self.label, {}).fetch(:services, {}))
    keys
  end

  def keys_for(provider)
    OpenStruct.new(external_service_keys[provider])
  end

end
