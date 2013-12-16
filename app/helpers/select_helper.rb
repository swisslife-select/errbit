module SelectHelper
  def users_for_select
    User.ordered.map{ |u| [u.name, u.id.to_s] }
  end
end
