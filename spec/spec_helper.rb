require File.join(File.dirname(__FILE__), '..', 'app.rb')

require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'rspec'

FakerApp.set :environment, :test

Rspec.configure do |config|
  def app
    FakerApp
  end
  config.include Rack::Test::Methods
end