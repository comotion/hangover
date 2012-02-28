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
def next_uri() =
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

def get_next() =
   next_request(next_uri())
end

next = request.dynamic(id="hangover:dynamic", get_next)
playout = smart_crossfade(server.insert_metadata(next))

# INPUTS
# cockup sources - at least one infallible one
#  easiest to detect a blank feed later in the chain
failsafes = fallback([playout, safeword, blank()])
input = fallback(track_sensitive=false, [live, failsafes])

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

