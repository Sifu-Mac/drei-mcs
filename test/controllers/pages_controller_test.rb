require "test_helper"

class PwaManifestTest < ActionDispatch::IntegrationTest
  test "pwa manifest references existing icon assets" do
    get "/manifest.json"

    assert_response :success
    assert_includes response.body, "/icon-192.png"
    assert_includes response.body, "/icon-512.png"
    assert_no_match %r{"/icon\.png"}, response.body
  end
end
