require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "auth pages send a restrictive content security policy with a nonce" do
    get new_session_path

    assert_response :success

    policy = response.headers.fetch("Content-Security-Policy")
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_includes policy, "script-src 'self' https://plausible.io 'nonce-"
    assert_includes policy, "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://api.fontshare.com 'nonce-"
    assert_includes policy, "style-src-attr 'unsafe-inline'"
    assert_select "script[type='importmap'][nonce]", count: 1
    assert_select "script:not([nonce])", count: 0
  end
end
