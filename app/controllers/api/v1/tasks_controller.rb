module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: [ :show, :update, :destroy, :complete, :claim, :unclaim, :assign, :unassign ]
      before_action :require_internal_workspace_member, only: [ :create, :update, :destroy, :complete, :claim, :unclaim, :assign, :unassign ]

      def next
        unless current_user.agent_auto_mode?
          head :no_content
          return
        end

        @task = current_user.current_workspace_tasks
          .joins(:board_column)
          .where(board_columns: { kind: BoardColumn.kinds[:active] }, blocked: false, agent_claimed_at: nil)
          .reorder(priority: :desc, position: :asc)
          .first

        @task ? render(json: task_json(@task)) : head(:no_content)
      end

      def pending_attention
        unless current_user.agent_auto_mode?
          render json: []
          return
        end

        @tasks = current_user.current_workspace_tasks
          .joins(:board_column)
          .where(board_columns: { kind: BoardColumn.kinds[:active] })
          .where.not(agent_claimed_at: nil)

        render json: @tasks.map { |task| task_json(task) }
      end

      def claim
        set_task_activity_info(@task)
        active_column = @task.board.board_columns.find_by(kind: BoardColumn.kinds[:active]) || @task.board.board_columns.ordered.first
        @task.update!(agent_claimed_at: Time.current, board_column: active_column)
        render json: task_json(@task)
      end

      def unclaim
        set_task_activity_info(@task)
        @task.update!(agent_claimed_at: nil)
        render json: task_json(@task)
      end

      def assign
        set_task_activity_info(@task)
        @task.update!(assigned_to_agent: true, assigned_at: Time.current)
        render json: task_json(@task)
      end

      def unassign
        set_task_activity_info(@task)
        @task.update!(assigned_to_agent: false, assigned_at: nil)
        render json: task_json(@task)
      end

      def index
        @tasks = current_user.current_workspace_tasks

        @tasks = @tasks.where(board_id: params[:board_id]) if params[:board_id].present?

        if params[:board_column_id].present?
          @tasks = @tasks.where(board_column_id: params[:board_column_id])
        elsif params[:status].present? && Task.statuses.key?(params[:status])
          kind = Task.legacy_status_to_column_kind(params[:status])
          @tasks = @tasks.joins(:board_column).where(board_columns: { kind: BoardColumn.kinds.fetch(kind) })
        end

        if params[:blocked].present?
          blocked = ActiveModel::Type::Boolean.new.cast(params[:blocked])
          @tasks = @tasks.where(blocked: blocked)
        end

        @tasks = @tasks.where("? = ANY(tags)", params[:tag]) if params[:tag].present?

        if params[:completed].present?
          completed = ActiveModel::Type::Boolean.new.cast(params[:completed])
          @tasks = @tasks.where(completed: completed)
        end

        @tasks = @tasks.where(priority: params[:priority]) if params[:priority].present? && Task.priorities.key?(params[:priority])
        @tasks = @tasks.where(owner: params[:owner]) if params[:owner].present? && Task.owners.key?(params[:owner])
        @tasks = @tasks.where(color: params[:color]) if params[:color].present? && Task::COLOR_VALUES.include?(params[:color])

        if params[:assigned].present?
          assigned = ActiveModel::Type::Boolean.new.cast(params[:assigned])
          @tasks = @tasks.where(assigned_to_agent: assigned)
        end

        @tasks = if params[:assigned].present? && ActiveModel::Type::Boolean.new.cast(params[:assigned])
          @tasks.reorder(assigned_at: :asc)
        else
          @tasks.reorder(board_column_id: :asc, position: :asc)
        end

        render json: @tasks.map { |task| task_json(task) }
      end

      def create
        board_id = params.dig(:task, :board_id) || params[:board_id]
        board = if board_id.present?
          current_user.current_workspace_boards.find(board_id)
        else
          workspace = current_user.current_workspace || current_user.owned_workspaces.create!(name: "DREI Asset Review")
          current_user.current_workspace_boards.first || workspace.boards.create!(user: current_user, campaign: workspace.campaigns.active.find_or_create_by!(name: "Allgemein"), name: "DREI Asset Review", icon: "📋", color: "gray")
        end

        @task = board.tasks.new(task_params)
        @task.user = current_user
        set_task_activity_info(@task)

        if @task.save
          render json: task_json(@task), status: :created
        else
          render json: { error: @task.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def show
        render json: task_json(@task)
      end

      def update
        set_task_activity_info(@task)
        if @task.update(task_params)
          render json: task_json(@task)
        else
          render json: { error: @task.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        @task.destroy!
        head :no_content
      end

      def complete
        set_task_activity_info(@task)
        target_kind = @task.completed? ? :backlog : :done
        column = @task.board.board_columns.find_by(kind: BoardColumn.kinds.fetch(target_kind)) || @task.board.board_columns.ordered.first
        @task.update!(board_column: column)
        render json: task_json(@task)
      end

      private

      def set_task
        @task = current_user.current_workspace_tasks.find(params[:id])
      end

      def set_task_activity_info(task)
        task.activity_source = "api"
        task.actor_name = request.headers["X-Agent-Name"]
        task.actor_emoji = request.headers["X-Agent-Emoji"]
        task.activity_note = params[:activity_note] || params.dig(:task, :activity_note)
      end

      def task_params
        params.require(:task).permit(:name, :description, :priority, :due_date, :status, :owner, :blocked, :board_id, :board_column_id, :color, tags: [])
      end

      def task_json(task)
        app_url = ENV.fetch("APP_URL", "https://#{ENV.fetch("APP_HOST", "mission.digitalbackup.cloud")}")
        {
          id: task.id,
          name: task.name,
          description: task.description,
          priority: task.priority,
          status: task.status,
          owner: task.owner,
          owner_label: task.owner_label,
          blocked: task.blocked,
          tags: task.tags || [],
          completed: task.completed,
          completed_at: task.completed_at&.iso8601,
          due_date: task.due_date&.iso8601,
          position: task.position,
          assigned_to_agent: task.assigned_to_agent,
          assigned_at: task.assigned_at&.iso8601,
          agent_claimed_at: task.agent_claimed_at&.iso8601,
          board_id: task.board_id,
          board_column_id: task.board_column_id,
          board_column_name: task.board_column&.name,
          board_column_kind: task.board_column&.kind,
          color: task.color,
          archived_at: task.archived_at&.iso8601,
          workspace_id: task.board.workspace_id,
          url: "#{app_url}/boards/#{task.board_id}/tasks/#{task.id}",
          created_at: task.created_at.iso8601,
          updated_at: task.updated_at.iso8601
        }
      end
    end
  end
end
