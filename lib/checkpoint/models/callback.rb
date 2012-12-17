# A callback protects a subtree of the pebblespace. It knows who to call to check
# if the current user has permission to perform a specific operation in this subtree.

class Callback < ActiveRecord::Base
  # Time to cache callbacks for a given path
  PATH_CALLBACKS_CACHE_TTL = 5*60
  ACCESS_DATA_TTL = 5*60

  belongs_to :location

  validates_presence_of :path, :url

  before_save :assign_location

  scope :of_realm, lambda { |realm|
    realm = realm.label unless realm.is_a?(String)
    joins(:location).where(:locations => {:label_0 => realm})
  }

  # Returns an array: [result, callback, reason]
  # May throw Pebblebed::HttpError if any of the callbacks fail
  def self.allow?(params)
    require_parameters(params, [:method, :uid, :identity])
    _, path, _ = Pebblebed::Uid.parse(params[:uid])
    # Forward params to all callbacks. Callbacks allow or disallow by returning a hash
    # with the key "allow". True means pass, false means deny. Callbacks returning anything
    # else will be ignored.
    urls_for_path(path).each do |url|
      response = Pebblebed::Http.post(url, params)
      record = JSON.parse(response.body)
      next unless record.keys.include?('allow') # skip if there is no allow key in the response
      # If dissallowed, return with the denying callback and reason supplied (if any)
      return [false, url, record['reason']] unless record['allow']
    end
    [true, nil, nil]
  end

  # Given a path, returns the callbacks for all relevant callbacks.
  def self.urls_for_path(path)
    $memcached.fetch("callbacks_#{path}", PATH_CALLBACKS_CACHE_TTL) do
      for_path(path).map(&:url)
    end
  end

  # The longer the path, the greater the specificity
  def specificity
    self.path.split('.').size
  end

  # Given a path, returns the relevant callbacks in order of specificity
  # (i.e. a callback of "a.b.c.d" is more specific than "a.b")
  def self.for_path(path)
    location_ids = Location.by_path("^#{path}").map(&:id)
    where(["location_id in (?)", location_ids]).sort{|a, b| b.specificity <=> a.specificity}
  end

  def realm
    Realm.find_by_label(self.location.label_0)
  end

  private

  def self.require_parameters(params, required)
    missing = required - params.keys
    raise ArgumentError, "#{missing.first} must be specified" unless missing.empty?
  end

  def assign_location
    self.location = Location.declare!(self.path)
  end
end
