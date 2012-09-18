class GroupSubtree < ActiveRecord::Base
  belongs_to :group

  validates_each :location do |record, attr, value|
    record.errors.add attr, "Invalid path '#{value}'" unless Pebblebed::Uid.valid_path?(value)
    record.errors.add attr, "must be in same realm as group" unless record.location_path_matches_realm?
  end

  def location_path_matches_realm?
    return false unless self.location && self.group
    self.location.split('.').first == self.group.realm.label
  end

  def uid
    "group_subtree:#{group.realm.label}.groups.#{group_id}$#{location}"
  end

end