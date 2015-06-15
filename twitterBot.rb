#!/usr/bin/env ruby
 
require 'yaml'
require 'Twitter'
require 'net/http'
require 'open-uri'
require 'Faker'

begin
	parsed = YAML.load(File.open('config/key.yml'))
rescue Exception => e
	puts "Could not parse YAML: #{e.message}"
end

client = Twitter::REST::Client.new do |config|
	twitter = parsed["twitter"]
	config.consumer_key        = twitter["consumer_key"]
	config.consumer_secret     = twitter["consumer_secret"]
	config.access_token        = twitter["access_token"]
	config.access_token_secret = twitter["access_token_secret"]
end

def fetch_random_words
	words = []

	3.times do
		words.push(Faker::Hacker.noun)
	end

	words.join(",").gsub(",", ".")
end

def fetch_map_position(words, client, parsed)
	url = parsed["what3words"]["url"] + "key=" + parsed["what3words"]["key"] + "&string=" + words
	begin
		data = Net::HTTP.get_response(URI.parse(url)).body
	rescue
		print "Connection error in fetching position."
	end

	lat, lng = parse_data(data, words, client, parsed)
	return lat, lng
end

def parse_data(data, words, client, parsed)
	data = JSON.parse(data)
	if data.has_key?("error") and data["error"] == "11"
		puts "FAILED"
		fetch_words_position(client, parsed)
	else
		update_twitter(data["position"][0], data["position"][1], words, client, parsed)
	end
end

def fetch_image(lat, lng, parsed)
	puts parsed["maps"]["url"] + "center=" + lat.to_s + "," + lng.to_s + "&zoom=14&size=512x512&maptype=roadmap&sensor=false"
	open('resources/image.png', 'wb') do |file|
	  file << open(parsed["maps"]["url"] + "center=" + lat.to_s + "," + lng.to_s + "&zoom=14&size=512x512&maptype=roadmap&sensor=false").read
	end
end

def delete_file
	File.delete("resources/image.png")
end

def fetch_words_position(client, parsed)
	words = fetch_random_words()
	puts words
	fetch_map_position(words, client, parsed)
end

def update_twitter(lat, lng, words, client, parsed)
	fetch_image(lat, lng, parsed)
	client.update_with_media(words, File.new("resources/image.png"))
	delete_file
end

fetch_words_position(client, parsed)

