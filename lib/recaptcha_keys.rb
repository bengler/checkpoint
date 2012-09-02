class RecaptchaKeys

  attr_reader :private, :public
  def initialize
    keys = YAML::load(File.open("config/recaptcha.yml"))['keys']
    @private = keys['private']
    @public = keys['public']
  end

end
