require "csv"

class Boards::ExportsController < ApplicationController
  before_action :set_board

  def show
    send_data "\uFEFF#{csv_body}",
      filename: "#{@board.name.parameterize.presence || 'board'}-#{Time.zone.today.iso8601}.csv",
      type: "text/csv; charset=utf-8",
      disposition: :attachment
  end

  private

  def set_board
    @board = current_user.current_workspace_boards.includes(:campaign).find(params[:id])
  end

  def csv_body
    CSV.generate(force_quotes: true) do |csv|
      csv << [
        "Kampagne", "Board", "Spalte", "Kartenname", "Beschreibung", "Farbe",
        "Assets erledigt", "Assets gesamt", "Asset-Fortschritt", "Tags",
        "Erstellt am", "Zuletzt geändert", "Abgeschlossen am"
      ]

      @board.board_columns.ordered.includes(tasks: :subtasks).each do |column|
        column.tasks.active.reorder(:position, :created_at).each do |task|
          done_assets = task.subtasks.count(&:done?)
          total_assets = task.subtasks.size

          csv << [
            @board.campaign.name,
            @board.name,
            column.name,
            task.name,
            task.description,
            task.color,
            done_assets,
            total_assets,
            total_assets.positive? ? "#{(done_assets.to_f / total_assets * 100).round}%" : "",
            task.tags.join(", "),
            format_time(task.created_at),
            format_time(task.updated_at),
            format_time(task.completed_at)
          ].map { |value| safe_cell(value) }
        end
      end
    end
  end

  def safe_cell(value)
    text = value.to_s
    text.match?(/\A\s*[=+\-@]/) ? "'#{text}" : text
  end

  def format_time(time)
    time&.in_time_zone&.strftime("%d.%m.%Y %H:%M")
  end
end
