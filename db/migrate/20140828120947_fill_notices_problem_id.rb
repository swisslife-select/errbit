class FillNoticesProblemId < ActiveRecord::Migration
  def up
    sql =<<-SQL
      UPDATE notices SET problem_id = errs.problem_id FROM errs WHERE errs.id = notices.err_id;
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
