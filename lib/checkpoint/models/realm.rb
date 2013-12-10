require 'ostruct'

class Realm < ActiveRecord::Base

  has_many :accounts
  has_many :identities
  has_many :domains
  belongs_to :primary_domain, :class_name => "Domain"

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

  def self.get_canonical_hostname(url)
    if url.index('://')
      hostname = URI.parse(url).host
    else
      hostname = url
    end
    if hostname[/api[.]no$/]
      Amedia::Properties.publications_service.get_top_domain(hostname) || hostname
    else
      hostname
    end
  end

  def self.find_by_url(url)
    hostname = get_canonical_hostname(url)
    search_strings_for_hostname(hostname) do |domain|
      result = Domain.resolve_from_host_name(domain).try(:realm)
      return result if result
    end
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
      if (yaml = YAML.load(self.service_keys))
        keys.merge!(yaml)
      else
        raise "Missing or malformed configuration for #<Realm:#{id} #{label}>"
      end
    end
    keys.merge!(self.class.environment_overrides.fetch(self.label, {}).fetch(:services, {}))
    keys
  end

  def keys_for(provider)
    OpenStruct.new(external_service_keys[provider])
  end

  private

  def self.search_strings_for_url(url, &block)
    host = url[/(?:https?\:\/\/)?([^\/\:]+)/,1]
    search_strings_for_hostname(host, &block)
  end

  # Provided a block, this method will yield variations on the host with increasing
  # specificity: 'foo.bar.example.com' will yield
  # "foo.bar.example.com", "bar.example.com", "example.com".
  def self.search_strings_for_hostname(host, &block)
    if host.include?('.')
      candidate = host.split('.')
      while candidate.size > 1
        yield candidate.join('.')
        candidate.shift
      end
    else
      yield host
    end
  end

end
