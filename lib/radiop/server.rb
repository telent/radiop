require 'sinatra/base'
require 'builder'

Radiop ||= Module.new
class Radiop::Server < Sinatra::Application
  set :root, Pathname.new(__FILE__).parent.parent.parent
  disable :show_exceptions
  get "/" do
    content_type "application/opensearchdescription+xml"
    builder :search_form, locals: { collection: settings.collection }
  end
  get '/search' do 
    fields=Hash[[:creator,:title,:album,:year].map {|p|
           [p,params[p]]
         }]
    content_type "application/opensearchdescription+xml"
    builder :tracks, locals: { 
      collection: settings.collection, 
      query: fields, 
      tracks: settings.collection.search(fields)
    }
  end
end
