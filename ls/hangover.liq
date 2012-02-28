#!/usr/bin/liquidsoap --errors-as-warnings
# watch out for the (_*_)
### we want:
# sleep!
# food
# world peace
# gentle parsers
# liquidsoap as our switch
#  unless we switch to live feed from somewhere
#  unless it all fails, in which case we want a fallback

# svitsj
#  -> auto
#  -> studio

# the nexturl is where we get the next track uri from
nexturl = "http://delta9.pl/next"
endurl = "http://delta9.pl/end"
blankurl = "http://delta9.pl/blank"
metaurl = "http://delta9.pl/meta"
noiseurl = "http://delta9.pl/noise"

set("log.file.path", "./penis")
set("log.stdout", true)
set("log.level", 4)

set("server.telnet", true)

# LIVE SOURCE
# studio: stream harbor, live stream comes in here
set("harbor.bind_addr","0.0.0.0")
live = input.harbor("live",port=8000,password="dubdabdub")

# FALLBACK SOURCE
# reads all files on startup, so will either fail
# on startup or never after (unless you underrun :-F)
safeword = playlist.safe(id="fail", "./fail.m3u");

# MAIN SOURCE
# auto:
def get_next() =
   srv = http.get(nexturl)
   html_status = snd(fst(fst(fst(srv))))
   if html_status == 200 then
      snd(srv)
   else      
      ""
   end       
end

def next_request(uri) =
   request.create("dyna:mic", indicators=[uri])
end

def next_one() =
   next_request(get_next())
end

def end_uri(sec,meta) =
   ignore(http.get(endurl^"/"^string_of(sec)))
end
def blank_uri() =
   ignore( http.get(blankurl))
end
def noise_uri() =
   ignore( http.get(noiseurl))
end
def meta_uri(stuff) =
   ignore( http.get(metaurl))
end

next = request.dynamic(id="hangover:dynamic", next_one)
onnext = on_end(id="endoftrack", end_uri,next)
playout = smart_crossfade(server.insert_metadata(onnext))

# INPUTS
failsafes = fallback([playout, safeword, blank()])
sources = fallback(track_sensitive=false, [live, failsafes])
input = 
  on_metadata(id="metadata!",meta_uri,
  on_blank(id="blank!",
    blank_uri,
    on_noise=noise_uri,
    sources
    )
  )

# META

# switch the url via telnet
def set_nexturl(url) =
   nexturl = url
   "url set to #{nexturl}"
end
server.register("nexturl", set_nexturl)

#store_metadata(input)
#osd_metadata(input)

# OUTPUTS

# kinda uninterrupted when buffered
output.alsa(input)
#output.external("nextprogram")
#output.icecast.vorbis(

