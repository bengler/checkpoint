# A banning automatically denies any action for identities with a given fingerprint.

class Banning < ActiveRecord::Base
  belongs_to :location
  belongs_to :realm

  validates_presence_of :fingerprint

  before_save :assign_location, :assign_realm

  scope :by_path, lambda { |path|
    if path == '*'
      nil
    else
      joins(:location).where(:locations => Pebbles::Path.to_conditions(path)).
        readonly(false)
    end
  }

  # Create a ban, unless a more general ban is currently in effect. If this ban shadows another ban, delete it
  def self.declare!(attributes)
    # Check if there is an equivalent or more general ban in effect
    banning = Banning.where(:fingerprint => attributes[:fingerprint]).by_path("^#{attributes[:path]}").first
    unless banning
      # Delete any bans shadowed by this ban
      Banning.where(fingerprint: attributes[:fingerprint]).
        by_path("#{attributes[:path]}.*").destroy_all

      banning = Banning.create!(attributes)
    end
    banning
  end

  # Takes an :uid and :identity. If a ban is in effect, the path of the ban is returned. If
  # no ban is in effect, false is returned.
  def self.banned?(params)
    require_parameters(params, [:uid, :identity])
    return false unless params[:identity] # No identity specified? Skip check.

    identity = Identity.find_by_id(params[:identity])
    return false unless identity # No such user, let someone else deal with that fact

    _, subject_path, _ = Pebblebed::Uid.parse(params[:uid])
    subject_path = subject_path.split('.')

    banned_paths_for(identity).each do |banned_path|
      banned_path = banned_path.split('.')
      # Skip if the banned path is more specific than the subject path?
      next if banned_path.length > subject_path.length
      # Skip if the path shared between banned_path and subject_path is different
      next if subject_path[0...banned_path.length] != banned_path
      # Oh noes, we have a ban!
      return banned_path.join('.')
    end
    false
  end

  def self.find_all_for(identity)
    where(["fingerprint in (?)", identity.fingerprints])
  end

  def self.banned_paths_for(identity)
    find_all_for(identity).map(&:path)
  end

  # The identities affected by this ban
  def identities
    Identity.where(:realm_id => self.realm.id).
      where(["fingerprints @@ ?", fingerprint])
  end

  # Returns all identities banned in a given path
  def self.identities_in_path(path)
    realm = Realm.find_by_label(realm) if realm.is_a?(String)
    Identity.where(:realm_id => realm.id).
      joins('bannings on identities.fingerprints @@ to_tsquery(bannings.fingerprint)').
      joins('locations on bannings.location_id = locations.id').
      where(:locations => Pebbles::Path.to_conditions(path))
  end

  private

  def self.require_parameters(params, required)
    missing = required - params.keys
    raise ArgumentError, "#{missing.first} must be specified" unless missing.empty?
  end

  def assign_location
    self.location = Location.declare!(self.path)
  end

  def assign_realm
    self.realm = Realm.find_by_label(self.path.split('.').first)
  end
end
