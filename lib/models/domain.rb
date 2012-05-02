require 'uri'
require 'simpleidn'

class Domain < ActiveRecord::Base

  belongs_to :realm
  after_save :ensure_primary_domain
  
  validates :name, :presence => {}, :uniqueness => {}
  validates_each :name do |record, attr, name|
    unless Domain.valid_name?(name)
      record.errors.add(attr, :invalid_name)
    end
  end

  # Check that name is RFC-compliant with regard to length and permitted characters.
  def self.valid_name?(name)
    name &&
      name.length <= RFC_NAME_LIMIT &&
      name.split('.').map(&:length).max <= RFC_NAME_LABEL_LIMIT &&
      SimpleIDN.to_ascii(name) =~ RFC_NAME_PATTERN
  end

  def name=(name)
    if name
      super(name.strip.downcase)
    else
      super(nil)
    end
  end

  private

    RFC_NAME_PATTERN = /\A[a-z0-9][a-z\.0-9-]+\z/ui.freeze
    RFC_NAME_LIMIT = 253
    RFC_NAME_LABEL_LIMIT = 63

    def ensure_primary_domain
      return unless self.realm
      unless self.realm.primary_domain
        self.realm.primary_domain = self
        self.realm.save!
      end
    end

end
