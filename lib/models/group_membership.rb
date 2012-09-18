class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :identity

  validates_each :identity do |record, attr, value|
    record.errors.add attr, "realm must match group realm" unless record.group.realm_id == value.realm_id
  end

  def uid
    "group_membership:#{group.realm.label}.groups.#{group_id}$#{id}"
  end
end
