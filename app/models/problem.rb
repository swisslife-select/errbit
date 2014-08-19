# Represents a single Problem. The problem may have been
# reported as various Errs, but the user has grouped the
# Errs together as belonging to the same problem.

class Problem < ActiveRecord::Base
  include Authority::Abilities
  include ProblemRepository
  include Distribution

  belongs_to :app, inverse_of: :problems
  has_many :errs, inverse_of: :problem, dependent: :destroy
  has_many :comments, inverse_of: :problem, dependent: :destroy
  has_many :notices, through: :errs

  counter_culture :app, column_name: ->(model){ "unresolved_problems_count" if model.unresolved? }

  distribution :message, :host, :user_agent

  validates_presence_of :environment

  before_create :cache_app_attributes
  after_initialize :default_values

  validates_presence_of :last_notice_at, :first_notice_at

  def default_values
    if self.new_record?
      self.notices_count ||= 0
      self.resolved = false if self.resolved.nil?
      self.first_notice_at ||= Time.new
      self.last_notice_at ||= Time.new
    end
  end

  def comments_allowed?
    Errbit::Config.allow_comments_with_issue_tracker || !app.issue_tracker_configured?
  end

  def resolve!
    self.update_attributes!(:resolved => true, :resolved_at => Time.now)
  end

  def unresolve!
    self.update_attributes!(:resolved => false, :resolved_at => nil)
  end

  def unresolved?
    !resolved?
  end

  def self.merge!(*problems)
    ProblemMerge.new(problems).merge
  end

  def merged?
    errs.length > 1
  end

  def unmerge!
    attrs = {:error_class => error_class, :environment => environment}
    problem_errs = errs.to_a
    problem_errs.shift
    [self] + problem_errs.map(&:id).map do |err_id|
      err = Err.find(err_id)
      app.problems.create(attrs).tap do |new_problem|
        err.update_attribute(:problem_id, new_problem.id)
        new_problem.reset_cached_attributes
      end
    end
  end

  def reset_cached_attributes
    ProblemUpdaterCache.new(self).update
  end

  def cache_app_attributes
    if app
      self.last_deploy_at = if (last_deploy = app.deploys.where(:environment => self.environment).last)
        last_deploy.created_at.utc
      end
      Problem.where(id: self).update_all(
        last_deploy_at: self.last_deploy_at
      )
    end
  end

  def issue_type
    # Return issue_type if configured, but fall back to detecting app's issue tracker
    attributes['issue_type'] ||=
    (app.issue_tracker_configured? && app.issue_tracker.label) || nil
  end

  def inc(attr, increment_by)
    self.update_attribute(attr, self.send(attr) + increment_by)
  end
end

