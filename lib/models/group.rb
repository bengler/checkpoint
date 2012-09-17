# Part of Pebbles Security Model. Implements access groups.

class Group < ActiveRecord::Base
  belongs_to :realm
  has_many :memberships, :class_name => "GroupMembership", :dependent => :destroy
  has_many :subtrees, :class_name => "GroupSubtree", :dependent => :destroy
  has_many :identities, :through => :memberships

  # Label must start with a non-digit character
  validates_format_of :label,
    :with => /^[a-zA-Z_-][a-zA-Z0-9_-]*$/,
    :if => lambda { |record| !record.label.nil? },
    :message => "must start with a non-digit character"

  validates_uniqueness_of :label,
    :scope => :realm_id,
    :allow_nil => true

  def self.find_by_label_or_id(identifier)
    return self.find(identifier) if identifier.is_a?(Numeric) or identifier =~ /^[0-9]+$/
    self.find_by_label(identifier)
  end
end
