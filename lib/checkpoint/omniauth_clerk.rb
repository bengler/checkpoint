class OmniauthClerk

  # Returns a hash of account attributes from auth data as provided by
  # omniauth, intended for use with Account.declare!
  # The options param is a convenient slot to put additional stuff that should be in account attributes.
  # see https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema for an overview of the data omniauth provides
  def self.account_attributes(auth_data, additional_attributes = {})
    profile_url = nil
    if auth_data['info']['urls'] and auth_data['info']['urls'].any?
      profile_url = auth_data['info']['urls'][auth_data['provider'].titleize]
    elsif auth_data['extra']['raw_info']
      profile_url = auth_data['extra']['raw_info']['link']
    end

    # Quickfix to deal with origo returning :location as a lat, lon hash. In these cases we want to convert it to json
    location = auth_data['info']['location']
    location = location.to_json unless location.is_a?(String) or location.nil?

    attributes = {
      :provider =>     auth_data['provider'],
      :uid =>          auth_data['uid'],
      :token =>        auth_data['credentials']['token'],
      :secret =>       auth_data['credentials']['secret'],
      :nickname =>     auth_data['info']['nickname'],
      :name =>         auth_data['info']['name'],
      :location =>     location.to_s,
      :image_url =>    auth_data['info']['image'],
      :description =>  auth_data['info']['description'],
      :email =>        auth_data['info']['email'],
      :phone =>        auth_data['info']['phone'],
      :profile_url =>  profile_url
    }
    attributes.merge(additional_attributes)
  end

end
