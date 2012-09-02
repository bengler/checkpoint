require 'erb'

class CheckpointV1 < Sinatra::Base

  helpers do

    def recaptcha_keys
      @recaptcha_keys ||= RecaptchaKeys.new
    end

    # This method marks the current session as human for up to two minutes
    def passed_captcha!
      $memcached.set("human:#{current_session_key}", "true", 60*2)
    end

    # Call this to clear the captcha flag once the action has been taken
    def clear_captcha!
      $memcached.delete("human:#{current_session_key}")
    end

    # Call this to verify that the current session has solved a captcha during the last couple of minutes
    def passed_captcha?
      $memcached.get("human:#{current_session_key}") == 'true'
    end
  end

  get "/auth/captcha" do
    template = ERB.new(File.read(File.expand_path(File.join(File.dirname(__FILE__), 'views/captcha.html.erb'))), nil, '-')
    continue_to = params[:continue_to]
    api_key = recaptcha_keys.public
    error = params[:error]
    template.result(binding)
  end

  post "/auth/captcha" do
    http = Net::HTTP
    recaptcha = nil
    Timeout::timeout(3) do
      recaptcha = http.post_form(URI.parse("http://www.google.com/recaptcha/api/verify"), {
        "privatekey" => recaptcha_keys.private,
        "remoteip"   => request_ip,
        "challenge"  => params[:recaptcha_challenge_field],
        "response"   => params[:recaptcha_response_field]
      })
    end
    answer, error = recaptcha.body.split.map { |s| s.chomp }
    if answer == 'true'
      passed_captcha!
      redirect params[:continue_to]
    else
      redirect url_with_params("/auth/captcha", :continue_to => params[:continue_to], :error => error)
    end
  end
end
