require 'spec_helper'

describe AppCopy do
  it "copy the necessary fields" do
    recipient_name = "recipient"
    recipient = Fabricate(:app, :name => recipient_name, :github_repo => "url")
    donor = Fabricate(:app_with_watcher, :name => "donor", :github_repo => "copy url")

    AppCopy.deep_copy_attributes recipient, donor
    expect(recipient.name).to be(recipient_name)
    expect(recipient.github_repo).to be(donor.github_repo)

    expect(donor.watchers.one?).to be true
    expect(recipient.watchers.one?).to be true

    watcher_email = recipient.watchers.first.email
    donor_watcher_email = donor.watchers.first.email

    expect(watcher_email.present?).to be true
    expect(watcher_email).to be(donor_watcher_email)
  end
end
