class IdentityTag < ActiveRecord::Base
  belongs_to :identity

  validates_presence_of :identity_id
  validates_presence_of :tag
end
