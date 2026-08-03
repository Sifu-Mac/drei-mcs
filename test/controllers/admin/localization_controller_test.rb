require "test_helper"

class Admin::LocalizationControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "admin dashboard is German" do
    get admin_root_path

    assert_response :success
    assert_select "title", "DB × DREI"
    assert_includes response.body, "Benutzer insgesamt"
    assert_includes response.body, 'data-controller="turbo-progress modal-manager"'
    assert_no_match(/Welcome|Total Users|Pending Invites/, response.body)
  end

  test "user administration is German" do
    get admin_users_path

    assert_response :success
    assert_select "title", "DB × DREI"
    assert_includes response.body, "Es gibt nur zwei Rollen"
    assert_includes response.body, "Letzte Anmeldung"
    assert_no_match(/Create user|Back to Dashboard|Last Login/, response.body)
  end

  test "invite administration is German" do
    get admin_invites_path

    assert_response :success
    assert_select "title", "DB × DREI"
    assert_includes response.body, "Benutzer einladen"
    assert_includes response.body, "Einladung senden"
    assert_no_match(/Invite user|Send invite|Back to Dashboard/, response.body)
  end
end
