module ProblemRepository
  extend ActiveSupport::Concern

  included do
    scope :resolved, where(resolved: true)
    scope :unresolved, where(resolved: false)
    scope :ordered, order("last_notice_at desc")
  end

  module ClassMethods
    def detect_by_param!(raw_param)
      param = raw_param.to_s

      return find(param) if param.match(/\A\d+\z/)
      return find_by_remote_id!(param) if column_names.include? 'remote_id' #old mongodb id

      raise ActiveRecord::RecordNotFound
    end

    def for_apps(apps)
      return where(app_id: apps.pluck(:id)) if apps.is_a? ActiveRecord::Relation
      where(app_id: apps.map(&:id))
    end

    def all_else_unresolved(fetch_all)
      if fetch_all
        scoped
      else
        unresolved
      end
    end

    def in_env(env)
      env.present? ? where(environment: env) : scoped
    end

    def ordered_by(sort, order)
      case sort
        when "app";            order("app_name #{order}")
        when "message";        order("message #{order}")
        when "last_notice_at"; order("last_notice_at #{order}")
        when "last_deploy_at"; order("last_deploy_at #{order}")
        when "count";          order("notices_count #{order}")
        else raise("\"#{sort}\" is not a recognized sort")
      end
    end

    def in_date_range(date_range)
      where(["first_notice_at <= ? AND (resolved_at IS NULL OR resolved_at >= ?)", date_range.end, date_range.begin])
    end

    def search(value)
      t = arel_table
      where(t[:error_class].matches("%#{value}%")
            .or(t[:where].matches("%#{value}%"))
            .or(t[:message].matches("%#{value}%"))
            .or(t[:app_name].matches("%#{value}%"))
            .or(t[:environment].matches("%#{value}%"))
      )
    end
  end

  def notices
    Notice.for_errs(errs).ordered
  end
end
