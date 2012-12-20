# RADIOP - RESTful Audio Discovery In Open Protocols

A minimum viable replacement for DAAP and DLNA and all that insanely overblown stuff which has been decreed necessary for the apparently simple task of copying digial audio bits from place A to place B.  We use

0. An HTTP server
1. OpenSearch to describe the allowable searches
2. XSPF to show the results thereof
3. HTTP Content-Negotiation to transcode (where necessary) and stream

Eagle-eyed readers will note that there is no provision for discovery of the HTTP server in the first place.  This is officially outside scope: you can use Zeroconf or something on a local network, or just write the address down.

OpenSearch allows us to describe a search by creator/album/title/etc.  The result of this search is an XSPF playlist containing links to 
resources on the same server describing audio files.  Requests for these resources are expected to contain valid Accept headers, which will be used by the server in determining how and whether it needs to transcode.

## Note on authentication/caching

If we rely on an upstream cache to avoid transcoding the same resource
repeatedly, we need to bottom out the implications of using https or
authentication

This may be as simple as "cache-control: public, no-cache": 'public'
means cacheable even though authenticated, no-cache means no serving
the cached response without revalidation (at which time we can check auth)

* transforms in caches

Cache-control: no-transform - shoud we use that?  probably

## Bitrates

Suppose we have all our music from 7digital as 320k mp3s and wish to
downsample for streaming on 3g.  We can't use the media type to trigger this as they're both audio/mpeg

I poropse to add 'Content-Transfer-Rate' as a name introducing a
maximum/average transfer rate -

* in a request

@Accept-Transfer-Rate: 192000@ => please mr server, can you aim for 
approximately that number of octets per second

* in a response

````
Content-Transfer-Rate: 128000 
Vary: content-transfer-rate,content-type
````

## Seeking/resume play (HTTP Ranges)

Consider looking at
http://www.greenbytes.de/tech/webdav/draft-ietf-httpbis-p5-range-latest.html#range.units

and defining 'seconds' as a range type, so the client could issues
partial requests for e.g. 0:20-1:30 without having to turn that into
bytes.  Would make seeking in the stream much easier

