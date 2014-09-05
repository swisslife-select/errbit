module SelectHelper
  def users_for_select
    User.ordered.map{ |u| [u.name, u.id.to_s] }
  end

  def states(klass)
    klass.state_machine.states.map{|s| [s.human_name, s.name]}
  end

  def default_environments
    %w[production staging development]
  end
end
