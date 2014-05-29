# Include to do a Search
# TODO: Need to be in a Dedicated Object ProblemsSearch with params like input
#
module ProblemsSearcher
  extend ActiveSupport::Concern

  included do
    expose(:selected_problems) {
      Array(Problem.find(err_ids))
    }

    expose(:err_ids) {
      (params[:problems] || []).compact
    }

  end
end
