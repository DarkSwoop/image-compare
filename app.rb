require 'models/image'
require 'sinatra'
require 'json'

database_configuration = YAML.load(File.read(File.join(settings.root, 'database.yml')))
ActiveRecord::Base.establish_connection(database_configuration)

get '/' do
  @accepted_count = Image.where(:approved => true).count
  @declined_count = Image.where(:approved => false).count
  @count = Image.images_left(200)
  haml :index
end

put '/update/:id' do
  content_type :json
  @image = Image.find(params[:id])
  approved = params[:approved].to_i == 1
  @image.update_attribute(:approved, approved)
  {:success => true}.to_json
end

post '/import_csv' do
  tempfile_path = params[:csv_file][:tempfile].path
  csv_data = File.read(tempfile_path)
  Image.import_from_csv(csv_data, "#{params[:csv_file][:filename].gsub(/[^\w]/, '-').sub(/\..*?$/,'')}-#{Time.now.strftime("%Y%m%d%H%M")}")
  redirect to('/')
end

get '/next/:count' do
  content_type :json

  @images = Image.next_unapproved(params[:count], params[:ids], params[:exclude_threshold_count])
  @images.map do |image|
    image.url.sub!('http://www.qype.com/', "http://ecdn#{rand(3)}.qypecdn.net/").sub!(/(.*_)original(\.\w+)$/, '\1xlarge\2')
    image
  end
  {:images => @images, :remaining => Image.images_left(200)}.to_json
end
