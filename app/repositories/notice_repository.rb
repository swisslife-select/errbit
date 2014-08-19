module NoticeRepository
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { reorder('created_at asc') }
    scope :reverse_ordered, -> { reorder('created_at desc') }
    scope :for_errs, ->(errs) { where(err_id: errs.pluck(:id)) }
    scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  end

  module ClassMethods
    def for_show(notice_id)
      find_by(id: notice_id) || reverse_ordered.first
    end
  end

  def previous
    problem.notices.reverse_ordered.where("notices.id < ?", id).first
  end

  def next
    problem.notices.ordered.where("notices.id > ?", id).first
  end
end
