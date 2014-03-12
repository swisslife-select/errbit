module AppRepository
  extend ActiveSupport::Concern
  included do

  end

  module ClassMethods
    def detect_by_param!(raw_param)
      param = raw_param.to_s

      return find(param) if param.match(/\A\d+\z/)
      return find_by_remote_id!(param) if column_names.include? 'remote_id' #old mongodb id

      raise ActiveRecord::RecordNotFound
    end
  end
end
