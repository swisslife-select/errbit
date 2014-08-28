require 'spec_helper'

describe Deploy do
  context 'being created' do
    context 'when the app has resolve_errs_on_deploy set to false' do
      it 'should not resolve the apps errs' do
        app = Fabricate(:app, :resolve_errs_on_deploy => false)
        3.times.each{Fabricate(:problem, :app => app)}
        Fabricate(:deploy, :app => app)
        expect(app.reload.problems.none?{|problem| problem.resolved?}).to eq true
      end
    end

    context 'when the app has resolve_errs_on_deploy set to true' do
      it 'should resolve the apps errs that were in the same environment' do
        app = Fabricate(:app, :resolve_errs_on_deploy => true)
        @prod_errs = 3.times.map{Fabricate(:problem, :app => app, :environment => 'production')}
        @staging_errs = 3.times.map{Fabricate(:problem, :app => app, :environment => 'staging')}
        Fabricate(:deploy, :app => app, :environment => 'production')
        expect(@prod_errs.all?{|problem| problem.reload.resolved?}).to eq true
        expect(@staging_errs.all?{|problem| problem.reload.resolved?}).to eq false
      end
    end

  end

  it "should produce a shortened revision with 7 characters" do
    expect(Deploy.new(:revision => "1234567890abcdef").short_revision).to eq "1234567"
  end
end

