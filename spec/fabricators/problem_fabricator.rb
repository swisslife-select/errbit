Fabricator(:problem) do
  app { Fabricate(:app) }
  comments { [] }
  error_class 'FooError'
  environment 'production'
  fingerprint 'some-finger-print'
end

Fabricator(:problem_with_comments, :from => :problem) do
  after_create { |parent|
    3.times do
      Fabricate(:comment, :problem => parent)
      parent.comments(true)
    end
  }
end

Fabricator(:problem_resolved, :from => :problem) do
  state_event :resolve
end
