class RenameStandardBoardColumns < ActiveRecord::Migration[8.0]
  def up
    rename_columns([
      [ "Eingang", "Produktionsplan", 0 ],
      [ "Kunden-Review", "DREI-Review", 2 ],
      [ "Änderungen angefordert", "Korrekturen", 3 ]
    ])
  end

  def down
    rename_columns([
      [ "Produktionsplan", "Eingang", 0 ],
      [ "DREI-Review", "Kunden-Review", 2 ],
      [ "Korrekturen", "Änderungen angefordert", 3 ]
    ])
  end

  private

  def rename_columns(changes)
    changes.each do |from, to, kind|
      execute <<~SQL.squish
        UPDATE board_columns
        SET name = #{connection.quote(to)}, updated_at = CURRENT_TIMESTAMP
        WHERE name = #{connection.quote(from)} AND kind = #{kind}
      SQL
    end
  end
end
