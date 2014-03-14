module NoticeRepository
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { reorder('created_at asc') }
    scope :reverse_ordered, -> { reorder('created_at desc') }
    scope :for_errs, ->(errs) { where(err_id: errs.pluck(:id)) }
    scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  end
end
