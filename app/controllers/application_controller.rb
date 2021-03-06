class ApplicationController < ActionController::Base
  include Clearance::Controller
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :strip_and_redirect_on_www
  after_action :record_user_access

  protected
  def admin?
    signed_in? && current_user.admin?
  end
  helper_method :admin?

  def record_user_access
    if signed_in?
      current_user.update_columns(last_request_at: Time.now, last_ip:request.remote_ip)
    end
  end

  def strip_and_redirect_on_www
    if Rails.env.production?
      if request.env['HTTP_HOST'] != 'coderwall.com'
        redirect_to request.url.sub("//www.", "//"), status: 301
      end
    end
  end

  def redirect_to_back_or_default(default = root_url)
    if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
      redirect_to :back
    else
      redirect_to default
    end
  end

  def background(&block)
    Thread.new do
      yield
      ActiveRecord::Base.connection.close
    end
  end
end
