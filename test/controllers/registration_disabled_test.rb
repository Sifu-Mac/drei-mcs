require "test_helper"

class RegistrationDisabledTest < ActionDispatch::IntegrationTest
  test "there is no public registration route" do
    assert_raises(NameError) { new_registration_path }
    assert_raises(NameError) { registration_path }
  end

  test "requesting the old registration path returns a routing error" do
    get "/registrations/new"
    assert_response :not_found
  end
end
