require 'minitest/spec'
require 'minitest/autorun'
require 'rack/test'
require 'radiop/server'

include Rack::Test::Methods

describe "/" do
  def app
    Radiop::Server
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
end
