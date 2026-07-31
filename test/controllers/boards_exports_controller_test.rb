require "test_helper"
require "csv"

class BoardsExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @board = boards(:one)
    @task = tasks(:one)
  end

  test "workspace client can download a safe, structured board CSV" do
    @task.update!(description: "=SUM(A1:A2)", tags: ["social", "print"])
    @task.subtasks.create!(title: "1:1", done: true)
    @task.subtasks.create!(title: "9:16", done: false)
    sign_in_as users(:client)

    get export_board_path(@board, format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], ".csv"

    rows = CSV.parse(response.body.delete_prefix("\uFEFF"))
    assert_equal [
      "Kampagne", "Board", "Spalte", "Kartenname", "Beschreibung", "Farbe",
      "Assets erledigt", "Assets gesamt", "Asset-Fortschritt", "Tags",
      "Erstellt am", "Zuletzt geändert", "Abgeschlossen am"
    ], rows.first
    assert_equal @board.campaign.name, rows.second[0]
    assert_equal "'=SUM(A1:A2)", rows.second[4]
    assert_equal ["1", "2", "50%"], rows.second.values_at(6, 7, 8)
    assert_equal "social, print", rows.second[9]
  end

  test "user cannot export a board outside the current workspace" do
    sign_in_as users(:two)

    get export_board_path(@board, format: :csv)

    assert_response :not_found
  end

  test "owner and member can export a board in their shared workspace" do
    [users(:admin), users(:one)].each do |user|
      sign_in_as user
      get export_board_path(@board, format: :csv)
      assert_response :success
      delete session_path
    end
  end
end
