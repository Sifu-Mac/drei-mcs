require "test_helper"

class ApiUsageRecordTest < ActiveSupport::TestCase
  test ".track! creates and increments the current month's record" do
    user = users(:one)
    month = Date.current.strftime("%Y%m").to_i
    ApiUsageRecord.where(user:, month:).delete_all

    2.times { ApiUsageRecord.track!(user) }

    assert_equal 2, ApiUsageRecord.find_by!(user:, month:).call_count
  end
end
