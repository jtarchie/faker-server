require "rubygems"
require "bundler/setup"
require "ffaker"
require "sinatra"
require "json"
require "pp"

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
        :base_url => "/#{base}",
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
        parameters =  klass.method(option).parameters
        if parameters.length > 0
          args = parse_arguments(parameters)
          if args.compact.length > 0
            { :text => klass.send(option, *args) }.to_json
          else
            { :text => klass.send(option) }.to_json
          end
        else
          { :text => klass.send(option) }.to_json
        end
      else
        [401, {:error=>"Unauthorized. Probably called method not allowed to access."}.to_json]
      end
    end
  end
  
  error ArgumentError do
    content_type :json
    [
      400,
      {:error => "Missing argument for method. Please GET / for available options."}.to_json
    ]
  end
  
  private
  
  def parse_arguments(parameters)
    parameters.collect do |type, name|
      parse_values(params[name])
    end
  end
  
  def parse_values(value)
    if value.is_a?(Hash)
      params = {}
      value.each do |k, v|
        params[k.to_sym] = parse_values(v)
      end
      params
    elsif value.to_i.to_s == value
      value.to_i
    elsif ["true","false"].include?(value)
      eval(value)
    else
      value
    end
  end
  
  def get_options(base, klass)
    allowed_options(klass).collect do |option|
      arguments = klass.method(option).parameters.collect do |type, name|
        {:name => name, :type => type}
      end

      {
        :url => "/#{base}/#{option}",
        :example => (klass.send(option) rescue nil),
        :params => arguments
      }
    end
  end
  
  def allowed_options(klass)
    klass.methods - Object.methods - [:k]
  end
end
