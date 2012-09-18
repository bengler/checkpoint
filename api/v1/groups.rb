class CheckpointV1 < Sinatra::Base

  helpers do
    def find_group_and_check_god_credentials(identifier)
      group = Group.where(:realm_id => current_realm.id).by_label_or_id(identifier).first
      halt 404, "No such group (#{identifier})" unless group
      check_god_credentials(group.realm_id)
      group
    end
  end

  # List all groups for the current realm
  get "/groups" do
    groups = Group.where(:realm_id => current_realm.id)
    pg :groups, :locals => { :groups => groups }
  end

  # Create a new group.
  #
  # @param [String] label A unique label used as an alternative identifier for this group (optional)
  post "/groups/?:label?" do |label|
    check_god_credentials
    group = Group.create!(:realm => current_realm, :label => label)
    pg :group, :locals => {:group => group}
  end

  # Retrieve a group.
  #
  # @param [String] identifier The id or label of the group
  get "/groups/:identifier" do |identifier|
    group = Group.where(:realm_id => current_realm.try(:id)).by_label_or_id(identifier).first
    halt 404 unless group
    pg :group, :locals => {:group => group}
  end

  # Delete a group.
  #
  # @param [String] identifier The id or label of the group
  delete "/groups/:identifier" do |identifier|
    group = find_group_and_check_god_credentials(identifier)
    group.destroy
    [204] # Success, no content
  end

  # Create a group membership.
  #
  # @param [String] group_identifier The label or id of the group
  # @param [Integer] identity_id The id of the member to be added to the group
  put "/groups/:group_identifier/memberships/:identity_id" do |group_identifier, identity_id|
    group = find_group_and_check_god_credentials(group_identifier)
    halt 204 if GroupMembership.find_by_group_id_and_identity_id(group.id, identity_id)
    identity = Identity.find(identity_id)
    halt 403, "Identity realm does not match group realm" unless identity.realm_id == group.realm_id
    group_membership ||= GroupMembership.create!(:group_id => group.id, :identity_id => identity_id)
    [204] # Success, no content
  end

  # Delete a group membership
  #
  # @param [String] group_identifier The label or id of the group
  # @param [Integer] identity_id The id of the member to be added to the group
  delete "/groups/:group_identifier/memberships/:identity_id" do |group_identifier, identity_id|
    group = find_group_and_check_god_credentials(group_identifier)
    group_membership = GroupMembership.find_by_group_id_and_identity_id(group.id, identity_id)
    group_membership.destroy if group_membership
    [204] # Success, no content
  end

  # Add a subtree to a group to grant access to its restricted documents
  #
  # @param [String] identifier The id or label of the group
  # @param [String] location The path of the location, e.g. 'apdm.badnwagon.secret_documents'
  put "/groups/:identifier/subtrees/:location" do |identifier, location|
    group = find_group_and_check_god_credentials(identifier)
    halt 204 if GroupSubtree.find_by_group_id_and_location(group.id, location)
    subtree = GroupSubtree.new(:group => group, :location => location)
    halt 403, "Subtree must be in same realm as group" unless subtree.location_path_matches_realm?
    subtree.save!
    [204] # Success, no content
  end

  # Remove a subtree from a group to deny access to its restricted documents. (The path must be
  # specified exactly as it has been added to the group. No magic will remove other granted
  # locations that may fall within the subtree of the specified location)
  #
  # @param [String] identifier The id or label of the group
  # @param [String] location The path of the location, e.g. 'apdm.badnwagon.secret_documents'
  delete "/groups/:group_identifier/subtrees/:location" do |identifier, location|
    group = find_group_and_check_god_credentials(identifier)
    subtree = GroupSubtree.find_by_group_id_and_location(group.id, location)
    subtree.destroy if subtree
    [204] # Success, no content
  end

  # Get all memberships for a group
  #
  # @param [String] identifier The id or label of the group
  get "/groups/:identifier/memberships" do |identifier|
    group = Group.where(:realm_id => current_realm.try(:id)).by_label_or_id(identifier).first
    halt 404, "No such group in this realm" unless group
    pg :memberships, :locals => { :memberships => group.memberships, :groups => nil}
  end

  # Get all memberships for an identity.
  #
  # @param [Integer] id The id of the identity in question
  get "/identities/:id/memberships" do |id|
    identity = Identity.find(id)
    halt 404, "No such identity in this realm" unless identity.realm_id == current_realm.try(:id)
    memberships = GroupMembership.where(:identity_id => identity.id).includes(:group)
    pg :memberships, :locals => { :memberships => memberships, :groups => memberships.map(&:group)}
  end

end