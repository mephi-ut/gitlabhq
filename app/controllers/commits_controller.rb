require "base64"

class CommitsController < ProjectResourceController
  include ExtractsPath

  # Authoriz
  skip_before_filter :authenticate_user!, only: [:show]
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    @repo = @project.repository
    @limit, @offset = (params[:limit] || 40), (params[:offset] || 0)

    @commits = @repo.commits(@ref, @path, @limit, @offset)
    @commits = CommitDecorator.decorate_collection(@commits)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render layout: false }
    end
  end
end
