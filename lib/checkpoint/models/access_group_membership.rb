class AccessGroupMembership < ActiveRecord::Base
  belongs_to :access_group
  belongs_to :identity

  validates_each :identity do |record, attr, value|
    record.errors.add attr, "realm must match group realm" unless record.access_group.realm_id == value.realm_id
  end

  def uid
    "access_group_membership:#{access_group.realm.label}.access_groups.#{access_group_id}$#{id}"
  end
end
