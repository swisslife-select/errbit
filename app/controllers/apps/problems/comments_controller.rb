class Apps::Problems::CommentsController < Apps::Problems::ApplicationController
  authorize_actions_for Comment

  def create
    @comment = resource_problem.comments.build(params[:comment].merge(:user_id => current_user.id))
    if @comment.valid?
      resource_problem.save
      flash[:success] = "Comment saved!"
    else
      flash[:error] = "I'm sorry, your comment was blank! Try again?"
    end
    redirect_to app_problem_path(resource_app, resource_problem)
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      flash[:success] = "Comment deleted!"
    else
      flash[:error] = "Sorry, I couldn't delete your comment for some reason. I hope you don't have any sensitive information in there!"
    end
    redirect_to app_problem_path(resource_app, resource_problem)
  end
end
