require "spec_helper"
require "json"

describe FakerApp do
  shared_examples_for "a JSON response" do
    it "returned valid JSON" do
      lambda {
        JSON.parse(last_response.body)
      }.should_not raise_error
    end
    it "has JSON content type" do
      last_response.content_type.should include "application/json"
    end
  end
  
  shared_examples_for "a valid JSON response" do
    it "was successful" do
      last_response.status.should == 200
    end
    it_should_behave_like "a JSON response"
  end
  
  shared_examples_for "an unauthorized response" do
    it "was unauthorized" do
      last_response.status.should == 401
    end
    it "has an error message" do
      json["error"].should == "Unauthorized. Probably called method not allowed to access."
    end
    it_should_behave_like "a JSON response"    
  end
  
  shared_examples_for "a valid Faker response" do
    it "has text" do
      json['text'].should_not be_nil
    end
  end
  
  shared_examples_for "an ArgumentError response" do
    it_should_behave_like "a JSON response"
    it "returns method not allowed" do
      last_response.status.should == 400
    end
    
    it "has an error message" do
      json['error'].should == "Missing argument for method. Please GET / for available options."
    end
  end
  
  let(:json) { JSON.parse(last_response.body) }
  
  describe "when getting API JSON docs" do
    context "GET /" do
      before { get '/' }
    
      it_should_behave_like "a valid JSON response"

      it "has all the Faker wrappers" do
        json.length.should == 21
      end
      
      it "describes each wrapper" do
        json.each do |item|
          item.keys.should =~ ["base_url", "options"]
          item["options"].length.should > 0
          item["options"].each do |option|
            option.keys.should =~ ["url", "example", "params"]
          end
        end
      end
    end
  end
  
  describe "when getting specific actions docs" do
    shared_examples_for "specific doc request" do
      it_should_behave_like "a valid JSON response"
      
      it "describes the def wrapper" do
        json.length.should > 0
        json.each do |option|
          option.keys.should =~ ["url", "example", "params"]
        end
      end
    end
    
    context "GET /address" do
      before { get '/address' }
      
      it_should_behave_like "specific doc request"
    end
    
    context "GET /module" do
      FakerApp::MAPPINGS.each do |base, klass|
        before { get "/#{base}"}
        
        it_should_behave_like "specific doc request"        
      end
    end
  end
  
  describe "when calling a specfic faker method" do
    before { get path, params }
    
    context "that exists" do
      context "that has arguments" do
        context "when none are passed" do
          let(:params) { {} }
          
          context "and are optional" do  
            let(:path) { '/hipster_ipsum/words' }
            it_should_behave_like "a valid JSON response"
            it_should_behave_like "a valid Faker response"
          end
          
          context "and are required" do
            let(:path) { '/faker/numerify' }

            it_should_behave_like "an ArgumentError response"
          end
        end

        context "when arguments are passed" do
          context "when passing the second argument, but missing the first argument" do
            let(:path) { '/html_ipsum/fancy_string' }
            let(:params) { {:include_breaks => "true"} }
            
            it_should_behave_like "an ArgumentError response"
          end
          
          context "when passing a numerical argument" do
            let(:path) { '/hipster_ipsum/words' }
            let(:params) { {:num => "6"} }

            it_should_behave_like "a valid JSON response"
            it_should_behave_like "a valid Faker response"
            it "has 6 words" do
              json["text"].length.should == 6
            end
          end
          
          context "when passing a boolean argument" do
            let(:path) { '/address/street_address' }
            
            context "when true" do
              let(:params) { {:include_secondary => "true"} }
              it_should_behave_like "a valid JSON response"
              it_should_behave_like "a valid Faker response"
              it "includes the secondary" do
                json["text"].should match /Apt|Suite/
              end
            end
            
            context "when false" do
              let(:params) { {:include_secondary => "false"} }
              it_should_behave_like "a valid JSON response"
              it_should_behave_like "a valid Faker response"
              it "doesn't include the secondary" do
                json["text"].should_not match /Apt|Suite/
              end
            end
          end
          
          context "when passing a string argument" do
            let(:path) { '/faker/numerify' }
            let(:params) { {:number_string => "####"} }
            it_should_behave_like "a valid JSON response"
            it_should_behave_like "a valid Faker response"
            
            it "returns a valid number string" do
              json["text"].should match /\d{4}/
            end
          end
          
          context "when passing a hash argument" do
            let(:path) { '/html_ipsum/p' }
            
            context "with nested true value" do
              let(:params) { {:count => 4, :options => {:include_breaks => "true"}} }
              it_should_behave_like "a valid JSON response"
              it_should_behave_like "a valid Faker response"
            
              it "returns with linebreaks" do
                json["text"].should include "<br>"
              end
            end
            
            context "with nested false value" do
              let(:params) { {:count => 4, :options => {:include_breaks => "false"}} }
              it_should_behave_like "a valid JSON response"
              it_should_behave_like "a valid Faker response"
            
              it "returns without linebreaks" do
                json["text"].should_not include "<br>"
              end
            end
          end
        end
      end

      context "that has no arguments" do
        let(:path) { '/lorem/word' }
        let(:params) { {} }
        it_should_behave_like "a valid JSON response"
        it_should_behave_like "a valid Faker response"
        
        it "has one word" do
          json['text'].should match /^\w+$/
        end
      end
    end

    context "that doesn't exist" do
      let(:path) { '/faker/does_not_exist' }
      let(:params) { {} }
      
      it_should_behave_like "an unauthorized response"
    end
    
    context "that are not allowed" do
      let(:path) { '/faker/k' }
      let(:params) { {} }
      
      it_should_behave_like "an unauthorized response"
    end
  end
end