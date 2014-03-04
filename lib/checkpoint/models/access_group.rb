# Part of Pebbles Security Model. Implements access groups.

class AccessGroup < ActiveRecord::Base

  LABEL_VALIDATOR = /\A[a-zA-Z_-][a-zA-Z0-9_-]*\z/

  belongs_to :realm
  has_many :memberships, :class_name => "AccessGroupMembership", :dependent => :destroy
  has_many :subtrees, :class_name => "AccessGroupSubtree", :dependent => :destroy
  has_many :identities, :through => :memberships

  # Label must start with a non-digit character
  validates_format_of :label,
    :with => LABEL_VALIDATOR,
    :if => lambda { |record| !record.label.nil? },
    :message => "must start with a non-digit character"

  validates_uniqueness_of :label,
    :scope => :realm_id,
    :allow_nil => true

  scope :by_label_or_id, lambda { |identifier|
    if identifier.is_a?(Numeric) or identifier =~ /^[0-9]+$/
      where(:id => identifier)
    else
      where(:label => identifier)
    end
  }

  def self.paths_for_identity(id)
    # Feel free to translate this into ActiveRecord query syntax at your leisure.
    # Kind regards, KO
    connection.select_values(<<-SQL)
      SELECT location
      FROM access_group_subtrees
      WHERE access_group_id IN (
        SELECT access_group_id
        FROM access_group_memberships
        WHERE identity_id = #{id}
      )
    SQL
  end

  def uid
    "access_group:#{realm.label}.access_groups$#{id}"
  end

end
