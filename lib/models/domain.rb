require 'uri'

class Domain < ActiveRecord::Base
  belongs_to :realm
  validates_format_of :name, :with => /^[a-z0-9\.\-\_]+$/
  validates_uniqueness_of :name
end
