module ProblemRepository
  extend ActiveSupport::Concern

  included do
    scope :resolved, -> { where(resolved: true) }
    scope :unresolved, -> { where(resolved: false) }
    scope :ordered, -> { order("last_notice_at desc") }
  end

  module ClassMethods
    def detect_by_param!(raw_param)
      param = raw_param.to_s

      return find(param) if param.match(/\A\d+\z/)
      return find_by!(remote_id: param) if column_names.include? 'remote_id' #old mongodb id

      raise ActiveRecord::RecordNotFound
    end

    def for_apps(apps)
      eager_load(:app).merge(apps)
    end

    def in_env(env)
      env.present? ? where(environment: env) : all
    end

    def in_date_range(date_range)
      where(["first_notice_at <= ? AND (resolved_at IS NULL OR resolved_at >= ?)", date_range.end, date_range.begin])
    end
  end
end
