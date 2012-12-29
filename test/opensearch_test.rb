require 'minitest/unit'
require 'minitest/spec'
require 'mocha/setup'
require 'minitest/autorun'
require 'rack/test'
require 'radiop/server'
require 'nokogiri'
require 'uri'
require 'set'

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

  it "links to search URL" do
    n = Nokogiri::XML(@r.body)
    template = n.css('OpenSearchDescription Url').find {|n|
      n[:type] == "application/xspf+xml"
    }[:template]
    template.must_match %r{\A/search\?}
    params = template.scan(/\?(.+)\Z/).first.first.split(/&amp;/)
    Set.new(params).must_equal Set.new(["creator={creator}", "album={album}", "title={title}", "year={year}", "format=xspf"])
  end
end

describe '/search' do
  before :each do
    @coll ||= mock('collection')
    coll = @coll
    @app ||= Sinatra.new(Radiop::Server) do
      set :collection, coll
    end
    @discs = [
              OpenStruct.new(creator: 'hello', album: '1', title: 'track 1'),
              OpenStruct.new(creator: 'hello', album: 'Hits', title: 'B side'),
              OpenStruct.new(creator: 'hello', album: 'Eponymous', title: 'welcome to the jungle'),
            ]
    @discs.each_with_index do |d,i| d.location="/data/#{i}" end
    @coll.expects(:search).returns(@discs)
    get '/search?creator=hello'
    @r = last_response
  end
  def app
    @app
  end

  it "is ok" do    
    @r.must_be :ok?
  end
  it "is a playlist" do
    n = Nokogiri::XML(@r.body)
    n.root.name.must_equal 'playlist'
  end
end
