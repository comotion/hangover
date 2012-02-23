#!/usr/bin/liquidsoap --errors-as-warnings
#### 
# watch out for the (_*_)
#
# purpoise: to boldly go..
### we want:
# sleep!
# food
# world peace
# gentle parsers
# input=externally-controlled one-song "consumer" playlist
# or rather:
#  liquidsoap is our switch
#  switching songs externally determined by get_next web service
#  unless we switch to live feed from somewhere
#  unless it all fails, in which case we want a fallback
# 
#  easiest to detect a blank feed later in the chain
# 
# we want to know what is playing, we want it synchronized
# with metadata, and we want to control input

# the nexturl is where we get the next track uri from
nexturl = "http://delta9.pl/next"

set("log.file.path", "./penis")
set("log.stdout", true)

set("server.telnet", true)

# FALLBACKS

# reads all files on startup, so will either fail
# on startup or never after (unless you underrun :-F)
safeword = playlist.safe(id="fail", "./fail.m3u");

# weird... and unsurprisingly annoying... and useless
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

#cmd = input.external(id="random",buffer=12., "cat /dev/urandom")
#keys = input.keyboard.sdl()
#sources = [keys]
#sources = [ input.mplayer("/home/comotion/downloads/torrent/The.Walking.Dead.S02E01.720p.HDTV.x264-IMMERSE.mkv"), sine() ]

# MAIN SOURCE

# a playlist that can be reloaded from the cli
# actually this is just for testing... real main source
# will be a dynamic get_next request queue
pair = playlist.reloadable("./win.m3u")
playout = smart_crossfade(mksafe(server.insert_metadata(snd(pair))))

reload = fst(pair)
def gah(link) =
   reload(uri=link)
   "yup"
end
server.register("reload",gah)

# SOURCE LIST

# cockup sources - at least one infallible one
sources =  [fail(), empty(), playout, safeword, eat_blank(blank()), weird]
#input = fallback(sources);

input = fallback(sources)

# META

#store_metadata(input)
#osd_metadata(input)

# OUTPUTS

# kinda uninterrupted when buffered
output.alsa(input)

#output.alsa(bufferize=false, input)
#output.jack(input)
#output.dummy(input)
#out(input) # too smart for my good
#output.external("nextprogram")
#output.icecast.vorbis(

# svitsj
#  -> auto
#  -> studio

# auto:

# console command
def set_nexturl(url) =
   nexturl = url
   "url set to #{nexturl}"
end

def next_uri() =
   srv = http.get(nexturl)
   html_status = snd(fst(fst(fst(srv))))
   if html_status == 200 then
      snd(srv)
   else      
      # Server is down, hardcode another fail?
      "./fail.m3u"
   end       
end

# a source is a list if uris... I guess?
def source_from_uri(uri) =
   if(file.exists(uri)) then
      playlist = request.create.raw(uri)
      result =
         if request.resolve(playlist) then
            playlist = request.filename(playlist)
            files = playlist.parse(playlist)
            list.map(snd,files)
         else  
            print("Couldn't read playlist: request resolution failed.") 
            []  
         end
      request.destroy(playlist)
      result
   else
      print("wtsnafu?")
         []
   end
end


# a request is a {local,remote,dynamically generated} file
# requests can be trees of resolution which are recursively resolved
# Currently supported protocols

# bubble: sqlite database 
# SMB, FTP and HTTP using ufetch (provided by our ocaml-fetch distribution)
# HTTP, HTTPS, FTP thanks to wget
# SAY for speech synthesis (requires festival): say:I am a robot resolves to the WAV file resulting from the synthesis.
# TIME for speech synthesis of the current time: time: It is exactly $(time), and you're still listening.
# ANNOTATE for manually setting metadata, typically used in annotate:nick="alice",message="for bob":/some/track/uri

#requests = request.equeue(id="nexapi")
# source.dynamic should change source snappily
# request.dynamic should play request given by func

# http.get(next)
# play next (filnavn, crossfade)
# http.get(played)


# TODO: should be something like
# request.dynamic(request.create.raw(get_uri)
# and for live streams, input.harbor

