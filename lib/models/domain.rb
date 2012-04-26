require 'uri'

class Domain < ActiveRecord::Base
  belongs_to :realm
  validates_format_of :name, :with => /^[a-z0-9\.\-]+$/
  validates_uniqueness_of :name

  after_save :ensure_primary_domain

  private

  def ensure_primary_domain
    return unless self.realm
    unless self.realm.primary_domain
      self.realm.primary_domain = self
      self.realm.save!
    end
  end
end
