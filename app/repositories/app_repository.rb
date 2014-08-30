module AppRepository
  extend ActiveSupport::Concern

  included do
    has_many :watchers_of_errors, -> { where(watching_errors: true) }, class_name: 'Watcher'
    has_many :watchers_of_deploys, -> { where(watching_deploys: true) }, class_name: 'Watcher'
  end

  module ClassMethods
    def detect_by_param!(raw_param)
      param = raw_param.to_s

      return find(param) if param.match(/\A\d+\z/)
      return find($1) if param.match(/\A(\d+)-.*\z/) #see App#to_param
      return find_by!(remote_id: param) if column_names.include? 'remote_id' #old mongodb id

      raise ActiveRecord::RecordNotFound
    end
  end

  # Accepts a hash with the following attributes:
  #
  # * <tt>:error_class</tt> - the class of error (required to create a new Problem)
  # * <tt>:environment</tt> - the environment the source app was running in (required to create a new Problem)
  # * <tt>:fingerprint</tt> - a unique value identifying the notice
  #
  def find_or_create_problem!(attrs)
    problem = problems.find_by fingerprint: attrs[:fingerprint]
    return problem if problem
    problems.create!(attrs.slice(:error_class, :environment, :fingerprint))
  end

  def error_recipients
    return application_wide_recipients if notify_all_users
    watchers_of_errors.map(&:address)
  end

  def deploy_recipients
    return application_wide_recipients if notify_all_users
    watchers_of_deploys.map(&:address)
  end

  def application_wide_recipients
    (User.with_not_blank_email.pluck(:email) + watchers.pluck(:email)).uniq
  end

  def last_five_deploys
    deploys.by_created_at.limit(5)
  end
end
