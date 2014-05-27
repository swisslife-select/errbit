atom_feed do |feed|
  feed.title("Deploys for #{resource_app.name}")
  feed.updated @deploys.first.created_at if @deploys.any?

  @deploys.each do |deploy|
    feed.entry deploy, url: app_deploy_url(resource_app, deploy) do |entry|
      entry.title "#{resource_app.name} was deployed to #{deploy.environment} by #{deploy.username}."
      entry.author do |author|
        author.name deploy.username
      end

      entry.content type: 'xhtml' do |xhtml|
        xhtml.strong 'Repository: '
        xhtml << link_to_repository(deploy.repository)
        xhtml.br

        xhtml.strong 'Revision: '
        xhtml << link_to_commit(deploy.repository, deploy.revision)
        xhtml.br

        if deploy.vcs_changes.any?
          xhtml.br
          xhtml.strong 'Changes:'
          xhtml.br
          xhtml << htmlize_changes(deploy.vcs_changes)
        end
      end
    end
  end
end
