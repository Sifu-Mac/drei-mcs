require "test_helper"

class Api::V1::ClientPermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:client)
    @board = boards(:one)
    @task = tasks(:one)
    @token = @client.api_tokens.create!(name: "Client permission test")
    @headers = { "Authorization" => "Bearer #{@token.token}" }
  end

  test "client API token remains read only for boards" do
    get api_v1_boards_url, headers: @headers
    assert_response :success

    post api_v1_boards_url, params: { name: "Client Board" }, headers: @headers
    assert_response :not_found
    patch api_v1_board_url(@board), params: { name: "Geändert" }, headers: @headers
    assert_response :not_found
    delete api_v1_board_url(@board), headers: @headers
    assert_response :not_found

    assert_not_equal "Geändert", @board.reload.name
  end

  test "client API token remains read only for every task mutation" do
    get api_v1_tasks_url, headers: @headers
    assert_response :success
    get api_v1_task_url(@task), headers: @headers
    assert_response :success

    post api_v1_tasks_url, params: { task: { board_id: @board.id, name: "Neu" } }, headers: @headers
    assert_response :not_found
    patch api_v1_task_url(@task), params: { task: { name: "Geändert" } }, headers: @headers
    assert_response :not_found
    patch complete_api_v1_task_url(@task), headers: @headers
    assert_response :not_found
    patch claim_api_v1_task_url(@task), headers: @headers
    assert_response :not_found
    patch unclaim_api_v1_task_url(@task), headers: @headers
    assert_response :not_found
    patch assign_api_v1_task_url(@task), headers: @headers
    assert_response :not_found
    patch unassign_api_v1_task_url(@task), headers: @headers
    assert_response :not_found
    delete api_v1_task_url(@task), headers: @headers
    assert_response :not_found

    assert_not_equal "Geändert", @task.reload.name
  end

  test "client cannot update agent settings over API" do
    patch api_v1_settings_url, params: { agent_name: "Client Agent", agent_auto_mode: true }, headers: @headers

    assert_response :not_found
    assert_not_equal "Client Agent", @client.reload.agent_name
  end
end
