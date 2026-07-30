require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  test "existing invited user can sign in with GitHub" do
    user = users(:one)
    auth = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "allowed-user-123",
      info: {
        email: user.email_address.upcase,
        image: "https://avatars.example.test/allowed-user.png"
      }
    )

    assert_difference("Session.count", 1) do
      get omniauth_callback_path(provider: "github"), env: { "omniauth.auth" => auth }
    end

    assert_redirected_to boards_url
    assert_equal "github", user.reload.provider
    assert_equal "allowed-user-123", user.uid
  end

  test "unknown GitHub user cannot create an account" do
    auth = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "unknown-user-456",
      info: {
        email: "unknown-github@example.com",
        image: "https://avatars.example.test/unknown-user.png"
      }
    )

    assert_no_difference([ "User.count", "Session.count" ]) do
      get omniauth_callback_path(provider: "github"), env: { "omniauth.auth" => auth }
    end

    assert_redirected_to new_session_path
    assert_equal "Account creation is restricted. Ask an admin to create your user first.", flash[:alert]
  end

  test "failure redirects with error message" do
    get auth_failure_path, params: { message: "access_denied" }

    assert_redirected_to new_session_path
    assert_equal "Authentication failed: Access denied", flash[:alert]
  end
end
