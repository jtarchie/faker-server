require "rubygems"
require "bundler/setup"
require "ffaker"
require "sinatra"
require "json"

class FakerApp < Sinatra::Base
  mappings = {
    :address => Faker::Address,
    :address_ca => Faker::AddressCA,
    :address_de => Faker::AddressDE,
    :company => Faker::Company,
    :faker => Faker,
    :internet => Faker::Internet,
    :name => Faker::Name,
    :name_cn => Faker::NameCN,
    :name_de => Faker::NameDE,
    :name_ja => Faker::NameJA,
    :name_ru => Faker::NameRU,
    :name_sn => Faker::NameSN,
    :geolocation => Faker::Geolocation,
    :hipster_ipsum => Faker::HipsterIpsum,
    :html_ipsum => Faker::HTMLIpsum,
    :lorem => Faker::Lorem,
    :lorem_cn => Faker::LoremCN,
    :phone_number => Faker::PhoneNumber,
    :phone_number_sn => Faker::PhoneNumberSN
  }
  
  get '/' do
    content_type :json
    JSON.pretty_generate(mappings.collect do |base, klass|
      {
        :base_url => "/#{klass.name.split('::').last.downcase}",
        :options => get_options(base, klass)
      }
    end)
  end
  
  mappings.each do |base, klass|
    get "/#{base}" do
      content_type :json
      JSON.pretty_generate(get_options(base, klass))
    end

    get "/#{base}/:option" do |option|
      content_type :json
      if allowed_options(klass).include?(option.to_sym)
        { :text => klass.send(option) }.to_json
      else
        401
      end
    end
  end
  
  private
  
  def get_options(base, klass)
    allowed_options(klass).collect do |option|
      begin
        {
          :url => "/#{base}/#{option}",
          :example => klass.send(option)
        }
      rescue
        nil
      end
    end.compact
  end
  
  def allowed_options(klass)
    klass.methods - Object.methods - [:k]
  end
end
