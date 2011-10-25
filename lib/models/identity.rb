class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy  
  belongs_to :primary_account, :class_name => 'Account'
  belongs_to :realm

  validates_presence_of :realm_id

  after_save :update_session_manager

  def ensure_primary_account
    self.primary_account ||= accounts.order('created_at').first
  end

  def update_session_manager
    SessionManager.update_identity_record(self) if self.primary_account_id_changed?
  end

end
