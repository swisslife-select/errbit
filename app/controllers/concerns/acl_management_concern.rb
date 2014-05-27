module AclManagementConcern
  def forbid(resource)
    raise Authority::SecurityViolation.new(current_user, params[:action], resource)
  end
end