require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "settings masks api token and renders German controls" do
    sign_in_as users(:admin)

    get settings_path

    assert_response :success
    assert_includes response.body, 'data-controller="token-visibility"'
    assert_includes response.body, 'aria-label="Maskierter API-Token"'
    assert_includes response.body, "Token kopieren"
    assert_includes response.body, "Token neu erstellen"
    assert_includes response.body, "Prompt kopieren"
    assert_no_match(/Copy token|Regenerate token|Connected Agent|Email Address/, response.body)
  end

  test "profile update uses German success message" do
    sign_in_as users(:admin)

    patch settings_path, params: { user: { email_address: users(:admin).email_address } }

    assert_redirected_to settings_path
    assert_equal "Profil wurde gespeichert.", flash[:notice]
  end
end
