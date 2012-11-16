class CheckpointV1 < Sinatra::Base

  helpers do
    def find_group_and_check_god_credentials(identifier)
      group = Group.where(:realm_id => current_realm.id).by_label_or_id(identifier).first
      halt 404, "No such group (#{identifier})" unless group
      check_god_credentials(group.realm_id)
      group
    end
  end

  # @apidoc
  # List all groups for the current realm.
  #
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups
  # @http GET
  # @example /api/checkpoint/v1/groups
  # @status 200 [JSON]

  get "/groups" do
    groups = Group.where(:realm_id => current_realm.id)
    pg :groups, :locals => { :groups => groups }
  end

  # @apidoc
  # Create a new group.
  #
  # @note Only for gods of the realm
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:label
  # @http POST
  # @optional [String] label A unique (within the realm) identifier for this group.
  # @example /api/checkpoint/v1/groups/secret_cabal
  # @status 201 [JSON]

  post "/groups/?:label?" do |label|
    check_god_credentials
    group = Group.create!(:realm => current_realm, :label => label)
    [201, pg(:group, :locals => {:group => group})]
  end

  # @apidoc
  # Retrieve metadata for a group.
  #
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:identifier
  # @http GET
  # @optional [String] identifier The id or label of the group.
  # @example /api/checkpoint/v1/groups/secret_cabal
  # @status 200 [JSON]

  get "/groups/:identifier" do |identifier|
    group = Group.where(:realm_id => current_realm.try(:id)).by_label_or_id(identifier).first
    halt 404 unless group
    pg :group, :locals => {:group => group}
  end

  # @apidoc
  # Delete a group.
  #
  # @note Only for gods of the realm.
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/api/checkpoint/v1/groups/:label
  # @http DELETE
  # @optional [String] identifier The id or label of the group.
  # @example /api/checkpoint/v1/groups/secret_cabal
  # @status 200 [JSON]

  delete "/groups/:identifier" do |identifier|
    group = find_group_and_check_god_credentials(identifier)
    group.destroy
    [204] # Success. No content..
  end

  # @apidoc
  # Add a member to the group.
  #
  # @note Only for gods of the realm.
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:group_identifier/memberships/:identity_id
  # @example /api/checkpoint/v1/groups/secret_cabal/memberships/1337
  # @http PUT
  # @optional [String] group_identifier The id or label of the group.
  # @optional [String] identity_id The id of the identity to add to the group.
  # @status 409 The identity is from a different realm than the group.
  # @status 204 [JSON]

  put "/groups/:group_identifier/memberships/:identity_id" do |group_identifier, identity_id|
    group = find_group_and_check_god_credentials(group_identifier)
    halt 204 if GroupMembership.find_by_group_id_and_identity_id(group.id, identity_id)
    identity = Identity.find(identity_id)
    halt 409, "Identity realm does not match group realm" unless identity.realm_id == group.realm_id
    group_membership ||= GroupMembership.create!(:group_id => group.id, :identity_id => identity_id)
    [204] # Success. No content.
  end

  # @apidoc
  # Delete a group membership.
  #
  # @note Only for gods of the realm.
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:group_identifier/memberships/:identity_id
  # @example /api/checkpoint/v1/groups/secret_cabal/memberships/1337
  # @http DELETE
  # @optional [String] group_identifier The id or label of the group.
  # @optional [String] identity_id The id of the identity to add to the group.
  # @status 200 [JSON]

  delete "/groups/:group_identifier/memberships/:identity_id" do |group_identifier, identity_id|
    group = find_group_and_check_god_credentials(group_identifier)
    group_membership = GroupMembership.find_by_group_id_and_identity_id(group.id, identity_id)
    group_membership.destroy if group_membership
    [204] # Success. No content..
  end

  # @apidoc
  # Add a path to the group.
  #
  # @note Only for gods of the realm.
  # @description The members of the group will be able to read all restricted content
  #   within the paths added to the group. I.e. if the path 'acme.secrets' is
  #   added to the group 'secret_cabal', its members will be able to read the secrets
  #   that are posted with the restricted flag within this path. This would include
  #   'post.secret_dossier:acme.secrets.top_secret.sinister_plans$3241'.
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:identifier/subtrees/:location
  # @example /api/checkpoint/v1/groups/acme/subtrees/acme.secrets
  # @http PUT
  # @optional [String] identifier The id or label of the group.
  # @optional [String] location The path to add to the group (i.e. acme.secrets).
  # @status 200 [JSON]

  put "/groups/:identifier/subtrees/:location" do |identifier, location|
    group = find_group_and_check_god_credentials(identifier)
    halt 204 if GroupSubtree.find_by_group_id_and_location(group.id, location)
    subtree = GroupSubtree.new(:group => group, :location => location)
    halt 403, "Subtree must be in same realm as group" unless subtree.location_path_matches_realm?
    subtree.save!
    [204] # Success. No content.
  end


  # @apidoc
  # Remove a path from a group.
  #
  # @note Only for gods of the realm
  # @description The path must be specified exactly as it has been added to the group.
  #   No magic will remove other granted locations that may fall within the subtree
  #   of the specified location.
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:group_identifier/subtrees/:location
  # @example /api/checkpoint/v1/groups/acme/subtrees/acme.secrets
  # @http DELETE
  # @optional [String] group_identifier The id or label of the group.
  # @optional [String] location The path to remove from the group (i.e. acme.secrets).
  # @status 200 [JSON]

  delete "/groups/:group_identifier/subtrees/:location" do |identifier, location|
    group = find_group_and_check_god_credentials(identifier)
    subtree = GroupSubtree.find_by_group_id_and_location(group.id, location)
    subtree.destroy if subtree
    [204] # Success. No content.
  end

  # @apidoc
  # Get all memberships for a group.
  #
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/groups/:identifier/memberships
  # @example /api/checkpoint/v1/groups/secret_cabal/memberships
  # @http GET
  # @optional [String] identifier The id or label of the group.
  # @status 200 [JSON]

  get "/groups/:identifier/memberships" do |identifier|
    group = Group.where(:realm_id => current_realm.try(:id)).by_label_or_id(identifier).first
    halt 404, "No such group in this realm" unless group
    pg :memberships, :locals => { :memberships => group.memberships, :groups => nil}
  end

  # @apidoc
  # Get all group memberships for an identity.
  #
  # @category Checkpoint/Groups
  # @path /api/checkpoint/v1/identities/:id/memberships
  # @example /api/checkpoint/v1/identities/1337/memberships
  # @http GET
  # @optional [String] id The id of the identity ('me' for current identity).
  # @status 404 No such identity in this realm.
  # @status 200 [JSON]

  get "/identities/:id/memberships" do |id|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such identity in this realm" unless identity.realm_id == current_realm.try(:id)
    memberships = GroupMembership.where(:identity_id => identity.id).includes(:group)
    pg :memberships, :locals => { :memberships => memberships, :groups => memberships.map(&:group)}
  end

end
