class RepositoryHosting
  class << self
    def hostings
      @hostings ||= Errbit::Config.repository_hostings.map { |attrs| new attrs }
    end

    def for_git_url(git_url)
      hostings.find{ |hosting| git_url.match(hosting.matcher) }
    end

    def github
      hostings.find{ |hosting| hosting.name == 'github' }
    end

    def bitbucket
      hostings.find{ |hosting| hosting.name == 'bitbucket' }
    end
  end

  attr_reader :name, :matcher, :base_url, :repo_path_template, :commit_path_template,
              :file_path_template, :file_line_anchor_template

  def initialize(attrs)
    params = attrs.clone
    matcher = params.delete 'matcher'
    @matcher = Regexp.new(matcher)
    params.each do |attr, value|
      instance_variable_set :"@#{attr}", value
    end
  end

  def repository(git_url)
    result = git_url.match matcher
    result[:repository]
  end

  def repository_url(git_url)
    repo = repository(git_url)
    path = repo_path_template % { repository: repo }
    path_to_url path
  end

  def commit_url(git_url, sha)
    repo = repository(git_url)
    path = commit_path_template % { repository: repo, sha: sha }
    path_to_url path
  end

  def file_url(git_url, sha, file_path)
    repo = repository(git_url)
    path = file_path_template % { repository: repo, sha: sha, file_path: file_path }
    path_to_url path
  end

  def file_with_line_url(git_url, sha, file_path, line)
    url = file_url(git_url, sha, file_path)
    anchor = file_line_anchor_template % { line: line }
    "#{url}##{anchor}"
  end

private
  def path_to_url(path)
    "#{base_url}/#{path}"
  end
end
