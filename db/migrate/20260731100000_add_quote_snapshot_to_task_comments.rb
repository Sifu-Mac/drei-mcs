class AddQuoteSnapshotToTaskComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :task_comments, :quoted_comment, foreign_key: { to_table: :task_comments, on_delete: :nullify }
    add_column :task_comments, :quoted_comment_body, :text
    add_column :task_comments, :quoted_comment_author_label, :string
    add_column :task_comments, :quoted_comment_created_at, :datetime
  end
end
