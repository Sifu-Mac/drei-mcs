class RenameApprovalAndDeliveryColumns < ActiveRecord::Migration[8.1]
  REVIEW_KIND = 2
  DONE_KIND = 4

  def up
    rename_columns("Freigegeben", "Freigabe", REVIEW_KIND)
    rename_columns("Fertig", "Angeliefert", DONE_KIND)
  end

  def down
    rename_columns("Freigabe", "Freigegeben", REVIEW_KIND)
    rename_columns("Angeliefert", "Fertig", DONE_KIND)
  end

  private

  def rename_columns(from, to, kind)
    execute <<~SQL.squish
      UPDATE board_columns
      SET name = #{connection.quote(to)}, updated_at = CURRENT_TIMESTAMP
      WHERE name = #{connection.quote(from)} AND kind = #{kind}
    SQL
  end
end
