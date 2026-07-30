require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get pages_home_url
    assert_response :success
  end

  test "pwa manifest references existing icon assets" do
    get "/manifest.json"

    assert_response :success
    assert_includes response.body, "/icon-192.png"
    assert_includes response.body, "/icon-512.png"
    assert_no_match %r{"/icon\.png"}, response.body
  end
end
