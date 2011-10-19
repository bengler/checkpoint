class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy
  belongs_to :primary_account, :class_name => 'Account'
  belongs_to :realm

  validates_presence_of :realm_id

  # Will destroy this identity and all its accounts leaving just a reference
  # to the succeeding identity in the orphaned_identities-table. Used when
  # merging identities.
  def orphanize!(new_identity)
    OrphanedIdentity.create!(:old_id => self.id, :identity => new_identity)
    self.destroy
  end

  def ensure_primary_account
    self.primary_account ||= accounts.order('created_at').first
  end

end
