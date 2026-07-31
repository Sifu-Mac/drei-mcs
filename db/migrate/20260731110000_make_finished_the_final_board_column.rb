class MakeFinishedTheFinalBoardColumn < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE board_columns
      SET kind = 2, updated_at = CURRENT_TIMESTAMP
      WHERE name = 'Freigegeben' AND kind = 4
    SQL

    execute <<~SQL.squish
      UPDATE tasks
      SET completed = FALSE, completed_at = NULL, blocked = FALSE, status = 5, updated_at = CURRENT_TIMESTAMP
      WHERE board_column_id IN (
        SELECT id FROM board_columns WHERE name = 'Freigegeben' AND kind = 2
      )
    SQL

    execute <<~SQL.squish
      UPDATE board_columns
      SET kind = 4, updated_at = CURRENT_TIMESTAMP
      WHERE name = 'Fertig' AND kind != 4
    SQL

    execute <<~SQL.squish
      UPDATE tasks
      SET completed = TRUE,
          completed_at = COALESCE(completed_at, CURRENT_TIMESTAMP),
          blocked = FALSE,
          status = 6,
          updated_at = CURRENT_TIMESTAMP
      WHERE board_column_id IN (
        SELECT id FROM board_columns WHERE name = 'Fertig' AND kind = 4
      )
    SQL

    execute <<~SQL.squish
      INSERT INTO board_columns (board_id, name, kind, position, created_at, updated_at)
      SELECT source.board_id, 'Fertig', 4, source.next_position, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM (
        SELECT board_id, MAX(position) + 1 AS next_position
        FROM board_columns
        WHERE name = 'Freigegeben' AND kind = 2
        GROUP BY board_id
      ) AS source
      WHERE NOT EXISTS (
        SELECT 1
        FROM board_columns existing
        WHERE existing.board_id = source.board_id AND existing.name = 'Fertig'
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Die Migration verändert den Abschlussstatus bestehender Karten und kann nicht sicher zurückgesetzt werden."
  end
end
