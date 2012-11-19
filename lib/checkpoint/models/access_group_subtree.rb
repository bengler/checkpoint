class AccessGroupSubtree < ActiveRecord::Base
  belongs_to :access_group

  validates_each :location do |record, attr, value|
    record.errors.add attr, "Invalid path '#{value}'" unless Pebbles::Uid.valid_path?(value)
    record.errors.add attr, "must be in same realm as access_group" unless record.location_path_matches_realm?
  end

  def location_path_matches_realm?
    return false unless self.location && self.access_group
    self.location.split('.').first == self.access_group.realm.label
  end

  def uid
    "access_group_subtree:#{access_group.realm.label}.access_groups.#{access_group_id}$#{id}"
  end

end
