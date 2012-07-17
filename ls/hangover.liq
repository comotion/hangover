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

#rate=44100
#set("frame.audio.samplefreq",rate)

# the nexturl is where we get the next track uri from
nexturl = "http://delta9.pl/next"
endurl = "http://delta9.pl/end"
blankurl = "http://delta9.pl/blank"
metaurl = "http://delta9.pl/meta"
noiseurl = "http://delta9.pl/noise"

set("log.file.path", "./playout.log")
set("log.stdout", true)
set("log.level", 3)
#set("clock.allow_streaming_errors",true) # allow funky happenings
#set("root.max_latency",7.) # reset the output when we're late instead of trying to catch up

set("server.telnet", true)
set("server.telnet.port", 1234)

# LIVE SOURCE
# studio: stream harbor, live stream comes in here
set("harbor.bind_addr","0.0.0.0")
live = buffer(id="livebuffer",fallible=true,input.harbor(id="liveharbor", "live",port=8008, icy=true, password="dubdabdub"))

# FALLBACK SOURCE
# reads all files on startup, so will either fail
# on startup or never after (unless you underrun :-F)
safeword = playlist.safe(id="fail", "./fail.m3u");
deadair = amplify(0.00001, noise())
weird = stretch(ratio=1.9,flanger(
         filter.iir.resonator.allpass(frequency=100.,
          filter(freq=323.,mode="low",q=1.3,wetness=0.42, 
            echo( add([
                  sine(445.),
                  amplify(3., 
                     comb(sine())
                  )
                ]))
          )
         )
        ))
ignore(weird)
ignore(safeword)
ignore(deadair)
#summe = sine()
#safeword = deadair

## UDP SOURCE

#udpin = input.udp(id="udpin",host="localhost", port=31338,"audio/pcm")
#udpin = input.oss(id="ALSA!")
#udpin = mksafe(input.external(id="udpin", "nc -u -l -p 31338"))
#udpin = mksafe(single

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
requests = request.queue()
mixq =  request.queue(id="mixq")

# FALLBACK no.X: random directory play (the "wontreach")
wontreach = playlist(id="random", mode="random",reload=600,"/srv/mu")
morn = playlist(id="morning", mode="random", reload=600, "/srv/mu/morn")
midd = playlist(id="midday", mode="random", reload=600, "/srv/mu/midd")
eve  = playlist(id="evening", mode="random", reload=600, "/srv/mu/eve")
program = switch(id="program",[
  ({ 5h-14h}, morn),
  ({ 14h-21h }, midd),
  ({ 21h-04h00 }, eve),
  ({ true }, wontreach)
  #({ 1w }, monday_source),
  #({ (6w or 7w) and 0h-12h }, week_ends_mornings),
])
         

# INPUTS
failsafes = eat_blank(id="blankfall", fallback(id="failsafes", [requests, program, wontreach, safeword , blank()]))
s = fallback(id="sources", track_sensitive=false, [live, playout, failsafes])

#s = smooth_add(normal=s,special=switch([({ 0m0s or 30m0s }, jingles_dyn)]))
sources = smooth_add(normal=s,special=mixq,p=0.5)
input = 
  on_metadata(id="metadata!",meta_uri,
  on_blank(id="blank!",
    blank_uri,
    on_noise=noise_uri,
    audio_to_stereo(id="source:stereo", sources)
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

#clock.assign_new(sync=false,[ # makes things glitchy over UDP
#   output.external(id="UT", 
#    %external(header=false,samplerate=44100,channels=2,restart_on_crash=true,
      #process="schroot -d /opt -- stereo_tool_cmd -s /opt/metafusion.sts - - " ),
#      process="stereo_tool_cmd -s /opt/modiknown.sts - - " ),
#    "socat - UDP-SENDTO:localhost:4200",
    #"socat - IP-DATAGRAM:delia:240,cool-write,shut-none",
#  input)
#])

# .. OGG ICE OUTPUT
#map_metadata(id,f,src)
#insert key1=“val1”,key2=“val2”,..
input = server.insert_metadata(id="meta",input)


output.icecast(id="ut",host='localhost', port=8888, password="dubdabdub", icy_metadata="true",mount="in",format="audio/ogg",
fallible=true,
#output.icecast(id="ut",host='localhost', port=8888, password="dubdabdub", icy_metadata="false",mount="in",format="audio/ogg",
    %external(header=false,samplerate=44100,channels=2,restart_on_crash=true,
      process="stereo_tool_cmd -s /opt/modiknown.sts - - | oggenc -q 10 -r - " ),
	#%ogg(%flac),
input)
