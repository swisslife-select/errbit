module FakeDiffer
  class << self
    def diff(*args)
      {
        url: 'git@github.com/company/project.git',
        commits: [
          {
            committed_date: 1392382940,
            authored_date: 1392382940,
            committer: {email: "mail@example.com", name: "author"},
            author: {email: "mail@example.com", name: "author"},
            message: "update submodule",
            sha: "be26814c48b8361823c05a98aba8c42838bd44f3",
            changes: [
              {
                stats: "1 +-",
                path: "lorem_submodule",
                type: "S",
                name: "lorem_submodule",
                url: "git@github.com/company/sub_project.git",
                sha_was: "3a58038",
                sha: "32a102f",
                commits: [
                  {
                    committed_date: 1392382403,
                    authored_date: 1392382403,
                    committer: {email: "mail@example.com", name: "author"},
                    author: {email: "mail@example.com", name: "author"},
                    message: "add desctiption",
                    sha: "32a102f5ca7d4ff4388c52440f65d6b40bde5e83",
                    changes: [
                       {stats: "4 ++++", path: "description.txt", type: "A"}
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    end
  end
end