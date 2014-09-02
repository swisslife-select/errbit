require 'spec_helper'

describe AppAuthorizer do
  let(:app) { Fabricate(:app) }

  context "with guest" do
    let(:user) { User::Guest.new }

    %w[create read update delete].each do |ability|
      it "deny #{ability} app" do
        expect(user.send("can_#{ability}?", app)).to be false
      end
    end

    it "deny read all apps" do
      expect(user.can_read? App).to be false
    end
  end

  context "with user" do
    let(:user) { Fabricate.build(:user) }

    %w[create read update delete].each do |ability|
      it "deny #{ability} app" do
        expect(user.send("can_#{ability}?", app)).to be false
      end
    end

    it "allow read all apps" do
      expect(user.can_read? App).to be true
    end
  end

  context "with watcher" do
    let(:watcher) { Fabricate(:user_watcher) }
    let(:user) { watcher.user }
    let(:app) { watcher.app }

    %w[create update delete].each do |ability|
      it "deny #{ability} app" do
        expect(user.send("can_#{ability}?", app)).to be false
      end
    end

    it "allow read app" do
      expect(user.can_read? app).to be true
    end

    it "allow read all apps" do
      expect(user.can_read? App).to be true
    end
  end

  context "with admin" do
    let(:user) { Fabricate.build(:admin) }

    %w[create read update delete].each do |ability|
      it "allow #{ability} app" do
        expect(user.send("can_#{ability}?", app)).to be true
      end
    end

    it "allow read all apps" do
      expect(user.can_read? App).to be true
    end
  end
end
