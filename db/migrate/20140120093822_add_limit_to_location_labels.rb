class AddLimitToLocationLabels < ActiveRecord::Migration
  def up
    10.times do |n|
      change_column :locations, :"label_#{n}", :string, :limit => 100
    end
  end

  def down
    10.times do |n|
      change_column :locations, :"label_#{n}", :string
    end
  end
end
