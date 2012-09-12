require 'rubygems'
require 'sinatra'
require 'flickraw'
require 'RMagick'
require 'open-uri'
require 'slim'
require 'sass'

FlickRaw.api_key= ENV['FLICKR_API_KEY']
FlickRaw.shared_secret = ENV['FLICKR_API_SECRET']

module PhotoSearch
  TAGS = %w{animal cute}
  def self.search(query)
    flickr.photos.search(text: "#{query}", tags: TAGS.join(',')).to_a.map { |result| Photo.new(result) }
  end
end

class Photo < Struct.new(:id)
  def initialize(results)
    super results["id"]
  end
end

class SizedPhoto < Struct.new(:width, :height, :url)
  def initialize(result)
    width = result["width"].to_i
    height = result["height"].to_i
    url = result["source"]

    super width, height, url
  end

  def self.all_sizes(photo)
    flickr.photos.getSizes(photo_id: photo.id).to_a.map { |result| SizedPhoto.new(result) }
  end
end

get '/' do
  slim :index
end

get '/img/*' do
  content_type 'image/jpeg'
  File.read(File.join 'img', params[:splat].first)
end

get '/*.css' do
  file = params[:splat].first.to_sym
  sass file
end

get '/:width/:height/:query' do
  query = params[:query]
  width = params[:width].to_i
  height = params[:height].to_i

  PhotoSearch.search(query).shuffle.each do |photo|
    sorted_photos = SizedPhoto.all_sizes(photo).sort_by do |sized_photo|
      sized_photo.width
    end

    @photo = sorted_photos.find do |sized_photo|
      sized_photo.width >= width &&
      sized_photo.height >= height
    end

    break if @photo
  end

  if @photo
    content_type 'image/jpeg'
    url = @photo.url

    image = open(url) do |f|
      Magick::Image.from_blob(f.read).first
    end

    image.crop!(Magick::CenterGravity, width, height)

    image.to_blob
  else
    content_type 'html'
    ''
  end
end
