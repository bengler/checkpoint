require 'pebblebed'
require_relative 'models/group'
require_relative 'models/group_subtree'
require_relative 'models/group_membership'

class RiverNotifications < ActiveRecord::Observer
  observe :group, :group_subtree, :group_membership

  def self.river
    @river ||= Pebblebed::River.new
  end

  def after_create(post)
    publish(post, :create)
  end

  def after_update(post)
    if post.deleted?
      publish(post, :delete)
    else
      publish(post, :update)
    end
  end

  def after_destroy(post)
    publish(post, :delete)
  end

  def publish(post, event)
    return if ENV['RACK_ENV'] == 'test'
    self.class.river.publish(:event => event, :uid => post.uid, :attributes => post.attributes.update('document' => post.merged_document))
  end

end
