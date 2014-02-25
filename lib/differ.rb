# TODO: rewrite when git libs will support submodules
module Differ
  class << self
    def diff(repository_name, repository_url, prev_commit_hash, commit_hash)
      cache_dir     = File.join(Dir.tmpdir, "errbit-checkout-cache")
      cache_dir_app = File.join(cache_dir, repository_name)

      begin
        FileUtils.rm_rf(cache_dir_app)
        FileUtils.mkdir_p(cache_dir_app)
        repo = Git.clone(repository_url, repository_name, path: cache_dir, recursive: true)

        commits = show_log(repo, commit_hash, prev_commit_hash)
        { url: repository_url, commits: commits }
      ensure
        FileUtils.rm_rf(cache_dir_app)
      end
    end

    def show_log(repo, deploy, prev_deploy)
      submodules = submodules_list(repo)

      log = repo.log.between(prev_deploy, deploy)

      log.map do |commit|
        attrs = commit_attrs(commit)

        diff = diff_parent(commit)
        attrs[:changes] = diff.map { |diff_file| diff_attrs(repo, submodules, diff, diff_file) }

        attrs
      end
    end

    def diff_attrs(repo, submodules, diff, diff_file)
      attrs = {
        stats: make_stats(diff, diff_file),
        path: diff_file.path,
      }

      case diff_file.type
      when 'new'
        attrs.merge type: 'A'
      when 'deleted'
        attrs.merge type: 'D'
      when 'modified'
        if submodules.include? diff_file.path
          s_attrs = submodule_attrs(repo, diff_file)
          attrs.merge s_attrs
        else
          attrs.merge type: 'M'
        end
      else
        attrs
      end
    end

    def submodule_attrs(repo, diff_file)
      submodule = diff_file.path
      s_repo = open_submodule(repo, submodule)
      previous_sha = diff_file.src #!= '0000000' ? diff_file.src : s_repo.log.last.sha
      last_sha = diff_file.dst
      {
        type: 'S',
        name: submodule,
        url: s_repo.remote.url,
        sha_was: previous_sha,
        sha: last_sha,
        commits: show_log(s_repo, last_sha, previous_sha),
      }
    end

    def commit_attrs(commit)
      {
          committed_date: commit.committer_date.to_i,
          authored_date: commit.author_date.to_i,
          committer: {
              email: commit.committer.email,
              name: commit.committer.name
          },
          author: {
              email: commit.author.email,
              name: commit.author.name
          },
          message: commit.message,
          sha: commit.sha,
      }
    end

    def open_submodule(main_repo, submodule_path)
      # https://github.com/git/git/blob/406da7803217998ff6bf5dc69c55b1613556c2f4/Documentation/RelNotes/1.7.8.txt#L109
      repository = File.join(main_repo.repo.path, 'modules', submodule_path)
      repository = File.join(main_repo.dir.path, submodule_path, '.git') unless File.directory? repository

      index = File.join(repository, 'index')
      dir = File.join(main_repo.dir.path, submodule_path)

      Git.open(dir, repository: repository, index: index)
    end

    def make_stats(diff, diff_file)
      max_length = 30
      stats = diff.stats
      path = diff_file.path
      pluses = stats[:files][path][:insertions]
      minuses = stats[:files][path][:deletions]

      signs = pluses + minuses
      if signs > max_length
        spluses  = pluses * max_length / signs
        sminuses = minuses * max_length / signs
      else
        spluses  = pluses
        sminuses = minuses
      end
      return '' if  signs <= 0
      "#{pluses > 0 ? pluses : minuses} #{'+' * spluses}#{'-' * sminuses}"
    end

    # show inverse(correct) diff
    def diff_parent(commit)
      base = commit.instance_variable_get :"@base"
      objectish = commit.instance_variable_get :"@objectish"
      parent = commit.parent

      Git::Diff.new(base, parent, objectish)
    end

    def submodules_list(repo)
      lib = Git::Lib.new repo
      response = lib.send :command, 'submodule status'
      submodules = response.split("\n")
      submodules.map do |s|
        data = s.match /\s(?<sha>\w+)\s(?<path>.+)\s\((?<branch>.*)\)/
        data[:path]
      end
    end
  end
end
