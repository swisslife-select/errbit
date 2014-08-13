module ApplicationHelper
  def generate_problem_ical(notices)
    RiCal.Calendar do |cal|
      notices.each_with_index do |notice,idx|
        cal.event do |event|
          event.summary     = "#{idx+1} #{notice.message.to_s}"
          event.description = notice.url if notice.url
          event.dtstart     = notice.created_at.utc
          event.dtend       = notice.created_at.utc + 60.minutes
          event.organizer   = notice.server_environment && notice.server_environment["hostname"]
          event.location    = notice.project_root
          event.url         = app_problem_url(:app_id => notice.problem.app.id, :id => notice.problem)
        end
      end
    end.to_s
  end

  def generate_ical(deploys)
    RiCal.Calendar { |cal|
      deploys.each_with_index do |deploy,idx|
        cal.event do |event|
          event.summary     = "#{idx+1} #{deploy.repository.to_s}"
          event.description = deploy.revision.to_s
          event.dtstart     = deploy.created_at.utc
          event.dtend       = deploy.created_at.utc + 60.minutes
          event.location    = deploy.environment.to_s
          event.organizer   = deploy.username.to_s
        end
      end
    }.to_s
  end

  def head(collection)
    collection.first(head_size)
  end

  def tail(collection)
    collection.to_a[head_size..-1].to_a
  end

  private
    def total_from_tallies(tallies)
      tallies.values.inject(0) {|sum, n| sum + n}
    end

    def head_size
      4
    end

end

