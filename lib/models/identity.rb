class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy
  belongs_to :primary_account, :class_name => 'Account'
  belongs_to :realm

  validates_presence_of :realm_id

  def ensure_primary_account
    self.primary_account ||= accounts.order('created_at').first
  end

end
