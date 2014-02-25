module TestRepo
  class << self
    def create
      FileUtils.mkdir_p(repos_dir_path)
      FileUtils.cd(repos_dir_path) do
        `tar xf #{archive_path}`
      end
    end

    def remove
      FileUtils.rm_rf(repos_dir_path)
    end

    def first_sha
      '8c2de60e0757348b2539f89fb2f603becc875354'
    end

    def last_sha
      'be26814c48b8361823c05a98aba8c42838bd44f3'
    end

    def test_repo_path
      File.join repos_dir_path, 'test_repo'
    end

    def repos_dir_path
       Rails.root.join('tmp', 'repositories')
    end

    def archive_path
      Rails.root.join 'spec', 'fixtures', 'test_repo.tar'
    end
  end
end
