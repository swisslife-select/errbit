class App < ActiveRecord::Base
  include Authority::Abilities
  include AppRepository

  serialize :email_at_notices, Array

  has_many :watchers, inverse_of: :app
  has_many :deploys, inverse_of: :app
  has_many :problems, inverse_of: :app, dependent: :destroy

  has_one :issue_tracker, inverse_of: :app, dependent: :destroy
  has_one :notification_service, inverse_of: :app, dependent: :destroy

  has_one :last_deploy, -> { order('created_at DESC') }, class_name: 'Deploy'

  def issue_tracker
    return @tentative_issue_tracker if has_tentative_issue_tracker?
    super
  end

  def has_tentative_issue_tracker?
    !!defined?(@tentative_issue_tracker)
  end

  alias_method :set_issue_tracker, :issue_tracker=
  def issue_tracker=(value)
    @tentative_issue_tracker = value
  end

  after_save :commit_issue_tracker, :if => :has_tentative_issue_tracker?

  def commit_issue_tracker
    set_issue_tracker @tentative_issue_tracker
    remove_instance_variable :@tentative_issue_tracker
  end

  def notification_service
    return @tentative_notification_service if has_tentative_notification_service?
    super
  end

  def has_tentative_notification_service?
    !!defined?(@tentative_notification_service)
  end

  alias_method :set_notification_service, :notification_service=
  def notification_service=(value)
    @tentative_notification_service = value
  end

  after_save :commit_notification_service, :if => :has_tentative_notification_service?

  def commit_notification_service
    set_notification_service @tentative_notification_service
    remove_instance_variable :@tentative_notification_service
  end


  before_validation :generate_api_key, :on => :create
  after_update :store_cached_attributes_on_problems
  after_initialize :default_values

  validates_presence_of :name, :api_key
  validates_uniqueness_of :name, :allow_blank => true
  validates_uniqueness_of :api_key, :allow_blank => true
  validates_associated :watchers
  validate :check_issue_tracker

  accepts_nested_attributes_for :watchers, :allow_destroy => true,
    :reject_if => proc { |attrs| attrs[:user_id].blank? && attrs[:email].blank? }
  accepts_nested_attributes_for :issue_tracker, :allow_destroy => true,
    :reject_if => proc { |attrs| !IssueTracker.subclasses.map(&:to_s).include?(attrs[:type].to_s) }
  accepts_nested_attributes_for :notification_service, :allow_destroy => true,
    :reject_if => proc { |attrs| !NotificationService.subclasses.map(&:to_s).include?(attrs[:type].to_s) }

  # Set default values for new record
  def default_values
    if self.new_record?
      self.email_at_notices ||= Errbit::Config.email_at_notices
    end
  end

  def last_deploy_at
    #(last_deploy = deploys.last) && last_deploy.created_at
    last_deploy.try(:created_at)
  end

  # Legacy apps don't have notify_on_errs and notify_on_deploys params
  def notify_on_errs
    !(super == false)
  end
  alias :notify_on_errs? :notify_on_errs

  def emailable?
    notify_on_errs? && error_recipients.any?
  end

  def notify_on_deploys
    !(super == false)
  end
  alias :notify_on_deploys? :notify_on_deploys

  def should_notify_on_deploy?
    notify_on_deploys? && deploy_recipients.any?
  end

  def repo_branch
    self.repository_branch.present? ? self.repository_branch : 'master'
  end

  def github_repo
    return unless repo_url?
    repo = RepositoryHosting.github
    return unless repo
    repo.repository repo_url
  end

  def github_repo?
    github_repo.present?
  end

  def bitbucket_repo
    return unless repo_url?
    repo = RepositoryHosting.bitbucket
    return unless repo
    repo.repository repo_url
  end

  def bitbucket_repo?
    bitbucket_repo.present?
  end

  def issue_tracker_configured?
    !!(issue_tracker.class < IssueTracker && issue_tracker.configured?)
  end

  def notification_service_configured?
    !!(notification_service.class < NotificationService && notification_service.configured?)
  end

  def unresolved_count
    unresolved_problems_count
  end

  def email_at_notices
    Errbit::Config.per_app_email_at_notices ? super : Errbit::Config.email_at_notices
  end

  def regenerate_api_key!
    update_column :api_key, SecureRandom.hex
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end

  protected

    def store_cached_attributes_on_problems
      problems.update_all(:app_name => name)
    end

    def generate_api_key
      self.api_key ||= SecureRandom.hex
    end

    def check_issue_tracker
      if issue_tracker.present?
        issue_tracker.valid?
        issue_tracker.errors.full_messages.each do |error|
          errors[:base] << error
        end if issue_tracker.errors
      end
    end
end

