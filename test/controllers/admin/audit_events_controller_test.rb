require "test_helper"

class Admin::AuditEventsControllerTest < ActionDispatch::IntegrationTest
  test "only admins can view the audit log" do
    AuditEvent.record!(actor: users(:admin), action: "test_event", target: users(:client), target_label: users(:client).email_address)
    sign_in_as users(:admin)
    get admin_audit_events_path
    assert_response :success
    assert_includes response.body, "Aktivitätsprotokoll"

    sign_in_as users(:client)
    get admin_audit_events_path
    assert_response :not_found
  end
end
