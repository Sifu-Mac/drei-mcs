# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self, :data, "https://fonts.gstatic.com"
    policy.img_src :self, :data
    policy.object_src :none
    policy.script_src :self, "https://plausible.io"
    policy.style_src :self, :unsafe_inline, "https://fonts.googleapis.com", "https://api.fontshare.com"
    policy.connect_src :self, "https://plausible.io"
    policy.base_uri :self
    policy.frame_ancestors :none
  end

  # A CSP nonce must be unpredictable and unique for every response.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
  config.content_security_policy_nonce_auto = true
end
