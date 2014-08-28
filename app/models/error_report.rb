##
# Processes a new error report.
#
# Accepts a hash with the following attributes:
#
# * <tt>:error_class</tt> - the class of error
# * <tt>:message</tt> - the error message
# * <tt>:backtrace</tt> - an array of stack trace lines
#
# * <tt>:request</tt> - a hash of values describing the request
# * <tt>:server_environment</tt> - a hash of values describing the server environment
#
# * <tt>:notifier</tt> - information to identify the source of the error report
#
class ErrorReport
  class << self
    def from_xml(xml)
      attrs = Hoptoad.parse_xml! xml
      new attrs
    end
  end

  cattr_accessor :fingerprint_strategy do
    Fingerprint
  end

  attr_reader :message, :request, :server_environment, :api_key, :notifier, :user_attributes, :framework

  def initialize(attributes)
    attributes.each{ |k, v| instance_variable_set(:"@#{k}", v) }
  end

  #tmp fix: if <error><class/></error> then @error_class = {} and ActiveRecord can't save it in text field
  def error_class
    @error_class.to_s
  end

  def rails_env
    rails_env = server_environment['environment-name']
    rails_env = 'development' if rails_env.blank?
    rails_env
  end

  def app
    @app ||= App.where(:api_key => api_key).first
  end

  def backtrace
    @normalized_backtrace ||= Backtrace.find_or_create(:raw => @backtrace)
  end

  def generate_notice!
    return unless valid?
    return @notice if @notice
    @notice = Notice.new(
      :message => message,
      :error_class => error_class,
      :backtrace_id => backtrace.id,
      :request => request,
      :server_environment => server_environment,
      :notifier => notifier,
      :user_attributes => user_attributes,
      :framework => framework
    )
    @notice.problem = problem
    @notice.save
    @notice
  end
  attr_reader :notice

  def problem
    @problem ||= app.find_or_create_problem!(
      :error_class => error_class,
      :environment => rails_env,
      :fingerprint => fingerprint
    )
  end

  def valid?
    !!app
  end

  private

  def fingerprint
    @fingerprint ||= fingerprint_strategy.generate(notice, api_key)
  end

end
