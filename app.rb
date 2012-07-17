require 'models/image'
require 'sinatra'
require 'json'

configure :production, :development do
  enable :logging
end

get '/' do
  @accepted_count = Image.where(:approved => true).count
  @declined_count = Image.where(:approved => false).count
  @count = Image.where('approved IS NULL').count
  haml :index
end

put '/update/:id' do
  content_type :json
  @image = Image.find(params[:id])
  approved = params[:approved].to_i == 1
  @image.update_attribute(:approved, approved)
  {:success => true}.to_json
end

get '/next/:count' do
  content_type :json

  @images = Image.next_unapproved(params[:count], params[:last_id])
  @images.to_json
end
