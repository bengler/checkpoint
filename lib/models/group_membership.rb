class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :identity

  validates_each :identity do |record, attr, value|
    record.errors.add attr, "Group and Identity realms must match" unless record.group.realm_id == value.realm_id
  end
end
