class DropboxController < ApplicationController

  skip_before_filter :authenticate_dropbox

  def index
  end

  def show
    consumer      = Dropbox::API::OAuth.consumer(:authorize)
    request_token = consumer.get_request_token
    session[:dropbox_oauth_request_token]  = request_token.token
    session[:dropbox_oauth_request_secret] = request_token.secret
    url = request_token.authorize_url(:oauth_callback => dropbox_callback_url)
    redirect_to url
  end

  def create
    consumer      = Dropbox::API::OAuth.consumer(:authorize)
    request_token = OAuth::RequestToken.new(consumer, session[:dropbox_oauth_request_token], session[:dropbox_oauth_request_secret])
    begin
      access_token = request_token.get_access_token
      session[:dropbox_token] = access_token.token
      session[:dropbox_secret] = access_token.secret
      session[:dropbox_uid] = params[:uid]
      create_folders
      flash[:notice] = 'Successfully connected to Dropbox!'
    rescue OAuth::Unauthorized => e
      flash[:error] = "Couldn't authorize with Dropbox (#{e.message})"
    end
    redirect_to "/"
  end

  def add_file 
    set_client
    @client.upload snippet_params[:name], snippet_params[:body]
    redirect_to "/"
  end

  private 

  def snippet_params
    params.require(:snippet).permit(:name, :body)
  end

  def set_client 
    consumer      = Dropbox::API::OAuth.consumer(:authorize)
    request_token = consumer.get_request_token
    @client = Dropbox::API::Client.new(token: session[:dropbox_token], secret: session[:dropbox_secret])
  end

  def create_folders
    client = Dropbox::API::Client.new(token: session[:dropbox_token], secret: session[:dropbox_secret])
      
    begin client.mkdir('vscode') rescue {} end
    begin client.mkdir('sublime') rescue {} end
    begin client.mkdir('sublime/User') rescue {} end
    @response = client.ls
  end

end

