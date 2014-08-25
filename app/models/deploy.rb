class Deploy < ActiveRecord::Base
  include Authority::Abilities
  include DeployRepository

  serialize :vcs_changes, Hash

  belongs_to :app, :inverse_of => :deploys

  after_commit :resolve_app_errs, on: :create, if: :should_resolve_app_errs?
  after_commit :store_cached_attributes_on_problems, on: :create

  validates_presence_of :username, :environment

  state_machine :notice_state, initial: :unprocessed, namespace: :notice do
    event :mark_as_delivered do
      transition :unprocessed => :delivered
    end

    state :unprocessed
    state :delivered
  end

  def resolve_app_errs
    app.problems.unresolved.in_env(environment).find_each { |problem| problem.resolve! }
  end

  def short_revision
    revision.to_s[0,7]
  end

  def should_notify?
    notice_unprocessed? && app.should_notify_on_deploy?
  end

  protected

    def should_resolve_app_errs?
      app.resolve_errs_on_deploy?
    end

    def store_cached_attributes_on_problems
      app.problems.in_env(environment).update_all(:last_deploy_at => created_at.utc)
    end
end

