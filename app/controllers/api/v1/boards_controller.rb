module Api
  module V1
    class BoardsController < BaseController
      before_action :set_board, only: [ :show, :update, :destroy ]
      before_action :require_internal_workspace_member, only: [ :create, :update, :destroy ]

      def index
        @boards = current_user.current_workspace_boards
          .left_joins(:tasks)
          .select("boards.*, COUNT(tasks.id) as tasks_count_cache")
          .group("boards.id")
          .reorder(:created_at)
        render json: @boards.map { |board| board_json(board, use_cached_count: true) }
      end

      def show
        render json: board_json(@board, include_tasks: params[:include_tasks] == "true")
      end

      def create
        workspace = current_user.current_workspace || current_user.owned_workspaces.create!(name: "DREI Asset Review")
        campaign = if params[:campaign_id].present?
          workspace.campaigns.active.find(params[:campaign_id])
        else
          workspace.campaigns.active.find_or_create_by!(name: "Allgemein")
        end
        @board = workspace.boards.new(board_params.merge(user: current_user, campaign: campaign))

        if @board.save
          render json: board_json(@board), status: :created
        else
          render json: { error: @board.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        if @board.update(board_params)
          render json: board_json(@board)
        else
          render json: { error: @board.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        if @board.workspace.boards.count <= 1
          render json: { error: "Das einzige Board kann nicht archiviert werden." }, status: :unprocessable_entity
        else
          @board.archive!
          head :no_content
        end
      end

      private

      def set_board
        @board = current_user.current_workspace_boards.find(params[:id])
      end

      def board_params
        params.permit(:name, :icon, :color)
      end

      def board_json(board, include_tasks: false, use_cached_count: false)
        json = {
          id: board.id,
          name: board.name,
          icon: board.icon,
          color: board.color,
          campaign_id: board.campaign_id,
          tasks_count: use_cached_count ? (board.tasks_count_cache || 0) : board.tasks.count,
          created_at: board.created_at.iso8601,
          updated_at: board.updated_at.iso8601,
          workspace_id: board.workspace_id
        }

        if include_tasks
          json[:tasks] = board.tasks.order(:status, :position).map do |task|
            {
              id: task.id,
              name: task.name,
              description: task.description,
              priority: task.priority,
              status: task.status,
              blocked: task.blocked,
              tags: task.tags || [],
              completed: task.completed,
              position: task.position,
              assigned_to_agent: task.assigned_to_agent
            }
          end
        end

        json
      end
    end
  end
end
