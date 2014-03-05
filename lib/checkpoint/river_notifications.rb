require 'pebblebed'
require_relative 'models/access_group'
require_relative 'models/access_group_subtree'
require_relative 'models/access_group_membership'

class RiverNotifications < ActiveRecord::Observer

  observe :access_group, :access_group_subtree, :access_group_membership

  def self.river
    @river ||= Pebblebed::River.new
  end

  def after_create(record)
    case record
      when AccessGroup, AccessGroupSubtree, AccessGroupMembership
        publish(record, :create)
    end
  end

  def after_update(record)
    case record
      when AccessGroup, AccessGroupSubtree, AccessGroupMembership
        publish(record, :update)
    end
  end

  def after_destroy(record)
    case record
      when AccessGroup, AccessGroupSubtree, AccessGroupMembership
        publish(record, :delete)
    end
  end

  private

    def publish(record, event)
      return if ENV['RACK_ENV'] == 'test'
      self.class.river.publish(:event => event, :uid => record.uid, :attributes => record.attributes)
    end

end
