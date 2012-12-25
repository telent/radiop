require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/mock'
require 'rack/test'
require 'radiop/server'
require 'nokogiri'

include Rack::Test::Methods

Collection = OpenStruct.new(directory: "/road/to/nowhere/inside" )

describe "/" do
  def app
    Sinatra.new(Radiop::Server) do
      set :collection, Collection
    end
  end

  before :each do
    get "/" 
    @r=last_response 
  end

  it { @r.must_be :ok? }

  it "has correct content-type" do
    @r.content_type.must_match %r{^application/opensearchdescription\+xml}
  end

  it "is XML" do
    @r.body.must_match /^<\?xml version="1.0" encoding="UTF-8"\?>/
  end

  it "has a description" do
    n = Nokogiri::XML(@r.body)
    desc = n.css('OpenSearchDescription Description').first.child.text
    desc.must_match "RADIOP server"
    desc.must_match Collection.directory
  end
end
