require 'spec_helper'

describe Differ do
  before :all do
    TestRepo.create
  end

  after :all do
    TestRepo.remove
  end

  it 'create correct diff' do
    repo = Git.open TestRepo.test_repo_path
    commit_hash = TestRepo.last_sha
    prev_commit_hash = TestRepo.first_sha

    changes = Differ.show_log repo, commit_hash, prev_commit_hash

    expect(changes.length).to be(4)

    first_commit = changes.first

    expect(first_commit[:message]).to be_eql('update submodule')
    expect(first_commit[:sha]).to be_eql('be26814c48b8361823c05a98aba8c42838bd44f3')
    fc_changes = first_commit[:changes]
    expect(fc_changes.length).to be(1)
    expect(fc_changes.first[:type]).to be_eql('S')
    expect(fc_changes.first[:commits].length).to be(1)
  end
end
