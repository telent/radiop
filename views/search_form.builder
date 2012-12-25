xml.instruct! :xml
xml.OpenSearchDescription xmlns: "http://a9.com/-/spec/opensearch/1.1/" do
  xml.ShortName "Dan's RADIOP server"
  xml.Description "Dan's RADIOP server at " + collection.directory
  xml.Contact "dan@telent.net"
  fields=[:creator, :album, :title, :year]
  xml.Url type: "application/xspf+xml",
  rel: "results",
  template: "/search?"+fields.map {|n| n.to_s+'={'+n.to_s+'}' }.join('&amp;') +"&amp;format=xspf"
  
end
