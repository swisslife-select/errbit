module BacktraceRepository
  extend ActiveSupport::Concern

  included do

  end

  module ClassMethods
    def find_or_create(attributes = {})
      new(attributes).similar || create(attributes)
    end
  end

  def similar
    Backtrace.find_by_fingerprint fingerprint
  end
end
