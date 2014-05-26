# Other authorizers should subclass this one
class ApplicationAuthorizer < Authority::Authorizer
  class << self
    # Any class method from Authority::Authorizer that isn't overridden
    # will call its authorizer's default method.
    #
    # @param [Symbol] adjective; example: `:creatable`
    # @param [Object] user - whatever represents the current user in your app
    # @return [Boolean]
    def default(adjective, user)
      user.admin?
    end

    #TODO: think about this
    def authorizes_to_edit_user_admin_field?(user, options = {})
      user.admin? && user.id != options[:user_id]
    end
  end
end
