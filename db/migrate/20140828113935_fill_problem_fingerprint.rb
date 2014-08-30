class FillProblemFingerprint < ActiveRecord::Migration
  def up
    sql =<<-SQL
      UPDATE problems SET fingerprint = (SELECT errs.fingerprint FROM errs WHERE errs.problem_id = problems.id LIMIT 1);
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
