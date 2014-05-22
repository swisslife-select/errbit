# Represents a single Problem. The problem may have been
# reported as various Errs, but the user has grouped the
# Errs together as belonging to the same problem.

class Problem < ActiveRecord::Base
  include ProblemRepository

  serialize :messages, Hash
  serialize :user_agents, Hash
  serialize :hosts, Hash

  belongs_to :app, inverse_of: :problems
  has_many :errs, inverse_of: :problem, dependent: :destroy
  has_many :comments, inverse_of: :err, dependent: :destroy
  counter_culture :app, column_name: -> (model) { "#{model.resolve_status}_problems_count" }

  validates_presence_of :environment

  before_create :cache_app_attributes
  after_initialize :default_values

  validates_presence_of :last_notice_at, :first_notice_at

  def default_values
    if self.new_record?
      self.user_agents ||= Hash.new
      self.hosts ||= Hash.new
      self.comments_count ||= 0
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

  # TODO Enumerize?
  def resolve_status
    resolved? ? 'resolved' : 'unresolved'
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
      self.app_name = app.name
      self.last_deploy_at = if (last_deploy = app.deploys.where(:environment => self.environment).last)
        last_deploy.created_at.utc
      end
      Problem.where(id: self).update_all(
        app_name: self.app_name,
        last_deploy_at: self.last_deploy_at
      )
    end
  end

  def remove_cached_notice_attributes(notice)
    update_attributes!(
      :hosts       => attribute_count_descrease(:hosts, notice.host),
      :user_agents => attribute_count_descrease(:user_agents, notice.user_agent_string)
    )
  end

  #FIXME: Problem with different error messages (PID, Time, etc.). They become too much and errbit slow write them.
  def messages
    m = notices.except(:order).group(:message).count
    @messages = {}
    m.each_pair do |key, value|
      index = attribute_index(key)
      @messages[index] = {'count' => value, 'value' => key}
    end
    @messages
  end

  def issue_type
    # Return issue_type if configured, but fall back to detecting app's issue tracker
    attributes['issue_type'] ||=
    (app.issue_tracker_configured? && app.issue_tracker.label) || nil
  end

  def inc(attr, increment_by)
    self.update_attribute(attr, self.send(attr) + increment_by)
  end

  private

    def attribute_count_descrease(name, value)
      counter, index = send(name), attribute_index(value)
      if counter[index] && counter[index]['count'] > 1
        counter[index]['count'] -= 1
      else
        counter.delete(index)
      end
      counter
    end

    def attribute_index(value)
      Digest::MD5.hexdigest(value.to_s)
    end
end

