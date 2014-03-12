module RepositoryHelper
  def repository_curl(git_url)
    hosting = RepositoryHosting.for_git_url git_url
    return git_url unless hosting
    hosting.repository_url(git_url)
  end

  def link_to_repository(git_url, options = nil)
    hosting = RepositoryHosting.for_git_url git_url
    return git_url unless hosting

    options ||= { target: '_blank' }
    link_to hosting.repository(git_url), hosting.repository_url(git_url), options
  end

  def link_to_commit(git_url, sha, options = nil)
    return if sha.blank?
    hosting = RepositoryHosting.for_git_url git_url
    return sha unless hosting

    options ||= { target: '_blank' }
    link_to sha, hosting.commit_url(git_url, sha), options
  end

  def link_to_repo_source_file(line, text = nil)
    return unless line.app.repo_url?

    git_url = line.app.repo_url
    body = text || line.file_name
    hosting = RepositoryHosting.for_git_url git_url
    return body unless hosting

    sha = line.app.repo_branch
    path = line.decorated_path + line.file_name
    href = hosting.file_with_line_url(git_url, sha, path, line.number)
    link_to(body, href, :target => '_blank')
  end
end
