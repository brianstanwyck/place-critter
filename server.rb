require 'rubygems'
require 'sinatra'
require 'flickraw'
require 'rmagick'
require 'open-uri'
require 'pry'

FlickRaw.api_key= ENV['FLICKR_API_KEY']
FlickRaw.shared_secret = ENV['FLICKR_API_SECRET']

class PhotoSearch
  def initialize(text)
  end
end

get '/:width/:height/:query' do
  query = params[:query]
  width = params[:width].to_i
  height = params[:height].to_i

  flickr.photos.search(text: "#{query}", tags: "animal").to_a.shuffle.each do |photo|
    @photo = flickr.photos.getSizes(photo_id: photo["id"]).sort_by do |size_response|
      size_response["width"].to_i
    end.find do |size_response|
      size_response["width"].to_i >= width &&
      size_response["height"].to_i >= height
    end
    break if @photo
  end

  if @photo
    content_type 'image/jpeg'
    url = @photo["source"]

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
