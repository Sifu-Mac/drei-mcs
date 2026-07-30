class BoardColumnsController < ApplicationController
  before_action :require_internal_workspace_member
  before_action :set_board
  before_action :set_board_column, only: [:update, :destroy, :move_left, :move_right]

  def create
    column = @board.board_columns.new(board_column_params)

    if column.save
      redirect_to board_path(@board), notice: "Spalte wurde hinzugefügt."
    else
      redirect_to board_path(@board), alert: column.errors.full_messages.join(", ")
    end
  end

  def update
    if @board_column.update(board_column_params)
      redirect_to board_path(@board), notice: "Spalte wurde aktualisiert."
    else
      redirect_to board_path(@board), alert: @board_column.errors.full_messages.join(", ")
    end
  end

  def destroy
    if @board.board_columns.count <= 1
      redirect_to board_path(@board), alert: "Mindestens eine Spalte muss im Board verbleiben."
      return
    end

    if @board_column.tasks.exists?
      redirect_to board_path(@board), alert: "Diese Spalte enthält noch Karten und kann nicht gelöscht werden."
      return
    end

    @board_column.destroy!
    normalize_positions
    redirect_to board_path(@board), notice: "Spalte wurde gelöscht."
  end

  def move_left
    @board_column.move_left!
    redirect_to board_path(@board), notice: "Spalte wurde verschoben."
  end

  def move_right
    @board_column.move_right!
    redirect_to board_path(@board), notice: "Spalte wurde verschoben."
  end

  private

  def set_board
    @board = current_user.current_workspace_boards.find(params[:board_id])
  end

  def set_board_column
    @board_column = @board.board_columns.find(params[:id])
  end

  def board_column_params
    params.require(:board_column).permit(:name, :kind)
  end

  def normalize_positions
    @board.board_columns.ordered.each_with_index do |column, index|
      column.update_column(:position, index + 1)
    end
  end
end
