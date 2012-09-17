class GroupSubtree < ActiveRecord::Base
  belongs_to :group

  validates_each :location do |record, attr, value|
    record.errors.add attr, "Invalid path '#{value}'" unless Pebblebed::Uid.valid_path?(value)
  end
end