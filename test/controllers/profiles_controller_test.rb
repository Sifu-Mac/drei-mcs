require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "settings renders the profile controls without an integration prompt" do
    sign_in_as users(:admin)

    get settings_path

    assert_response :success
    assert_includes response.body, "Profil speichern"
    assert_not_includes response.body, "OpenClaw"
    assert_not_includes response.body, "Agent-Prompt"
    assert_not_includes response.body, "https://github.com/Sifu-Mac/drei-mcs"
    assert_not_includes response.body, "https://discord.gg/bJQrNasMC6"
  end

  test "profile update uses German success message" do
    sign_in_as users(:admin)

    patch settings_path, params: { user: { email_address: users(:admin).email_address } }

    assert_redirected_to settings_path
    assert_equal "Profil wurde gespeichert.", flash[:notice]
  end

  test "profile accepts a valid avatar" do
    user = users(:admin)
    sign_in_as user

    patch settings_path, params: { user: { avatar: uploaded_png(filename: "avatar.png") } }

    assert_redirected_to settings_path
    assert user.reload.avatar.attached?
  end

  test "profile rejects corrupt avatar and removes its blob" do
    user = users(:admin)
    sign_in_as user

    assert_no_difference [ "ActiveStorage::Blob.count", "ActiveStorage::Attachment.count" ] do
      patch settings_path,
        params: { user: { avatar: uploaded_png(filename: "avatar.png", bytes: "not an image") } }
    end

    assert_response :unprocessable_entity
    assert_not user.reload.avatar.attached?
  end
end
