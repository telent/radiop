require 'sinatra/base'
require 'builder'
Radiop ||= Module.new
class Radiop::Server < Sinatra::Application
  set :root, Pathname.new(__FILE__).parent.parent.parent
  get "/" do
    content_type "application/opensearchdescription+xml"
    builder :search_form
  end  
end
