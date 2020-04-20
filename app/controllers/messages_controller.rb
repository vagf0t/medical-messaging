class MessagesController < ApplicationController
  def show
    @message = Message.find(params[:id])
    @message.set_to_read
  end

  def new
    @message = Message.new(original_message_id: params[:original_message_id])
  end

  def create
    @message = Message.build(params[:message][:body], params[:message][:original_message_id])
    if @message.save
      @message.inbox.update_unread
      redirect_to message_path(id: params[:message][:original_message_id]), notice: 'Your reply was sent!'
    else
      redirect_to new_message_path(original_message_id: params[:message][:original_message_id]), notice: 'Your reply was not sent. Please try again'
    end
  rescue OriginalMessageNotFound, ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  rescue HackAttempt
    render file: "#{Rails.root}/public/403.html", layout: false, status: 403
  end

  def prescription
    result = Message.request_prescription(params[:original_message_id])
    if result.blank?
      redirect_to root_path, notice: 'Pending payment! Bear with us while we process your request.'
    else
      redirect_to message_path(id: result[:id]), notice: result[:notice]
    end
  rescue OriginalMessageNotFound, ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  rescue HackAttempt
    render file: "#{Rails.root}/public/403.html", layout: false, status: 403
  end

  private

  def message_params
    params.require(:message).permit(:body, :original_message_id)
  end
end
