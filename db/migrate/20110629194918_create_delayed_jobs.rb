class CreateDelayedJobs < ActiveRecord::Migration
  def self.up
  end
  
  def self.down
    drop_table :delayed_jobs  
  end
end
