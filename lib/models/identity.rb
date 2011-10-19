class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy
  belongs_to :primary_account, :class_name => 'Account'
  belongs_to :realm

  validates_presence_of :realm_id

  def ensure_primary_account
    self.primary_account ||= accounts.order('created_at').first
  end

  def as_json(*args)
    result = {
      id: self.id,
      realm: self.realm.label,
      accounts: self.accounts.map(&:provider)
    }
    if self.primary_account
      result[:profile] = { 
        provider: self.primary_account.provider,
        nickname: self.primary_account.nickname,
        name: self.primary_account.name,
        profile_url: self.primary_account.profile_url,
        image_url: self.primary_account.image_url,
        description: self.primary_account.description
      }
    end
    result    
  end

end
