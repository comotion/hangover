#!/usr/bin/liquidsoap
set("log.file.path", "./penis.UT")
set("log.stdout", true)
set("log.level", 4)
set("clock.allow_streaming_errors",true) # allow funky happenings
#set("frame.audio.samplerate",44100)

set("server.telnet.port",4444)
set("server.socket.path","iceout.sock")
set("server.socket",true)
set("server.telnet", true)


#source = eat_blank(id="hangover",track_sensitive=false, buffer(fallible=true,input.external(id="HANGOVER", 
	#restart_on_error=true,restart=true,
	#"nc -lup 4200")
#))
set("harbor.bind_addr","0.0.0.0")
source= strip_blank(id="instrip", length=5.,input.harbor(id="inharbor", "in", icy=true,port=8888, password="dubdabdub"))


deadair = amplify(id="deadair",1.00001, noise())
deadair = rewrite_metadata([("artist","BASSIVE"), ("title", "BASSOFF")],deadair)
ignore(deadair)
                                                                   
# FALLBACK no.X: random directory play (the "wontreach")           
wontreach = playlist(id="random", mode="random",reload=600,"/srv/mu")
                      
input = fallback(id="IN",track_sensitive=false, [source, wontreach, deadair])

# based on output.aplay
def output.dabplus(
    ~id,
    ~dest,
    ~port="15002",
    ~samplerate=44100,
    ~channels=2,
    ~bitrate=96,
    ~padport=14000,
    ~padbytes=25,
    fmt, s)
  def crcdabplus(m) =
    "chroot /dabplus crc-dabplus -b #{bitrate} -c #{channels}  -r 48000 -g -d tcpserver://:#{padport} \
    -p #{padbytes} -t dls -q 2 -E \
    -f 'audio/x-raw-int,rate=#{samplerate},channels=#{channels},width=16,depth=16,signed=true,endianness=1234' \
    | resocat - TCP:#{dest}:#{port},forever"
    #-o tcpclientsink://host=#{dest},port=#{port}"
  end
  output.external( id=id,fallible=true, fmt, crcdabplus("blah"), s)
end

# .. DAB OUTPUT PIPE
#clock.assign_new(sync=false,[output.dabplus(id="dabplus", dest="tx.radionova.no",port="15002",
       #%wav(header=false,channels=2), input)])

#clock.assign_new(sync=false,[output.external(id="dabplus", %wav(header=false,channels=2),
#	"/opt/dabcmd.sh", input)])

#clock.assign_new(sync=false,[output.external(id="dabplus", %wav(header=false,channels=2),
#	"/opt/dabcmd.sh", input)])

# .. ICECAST OUTPUT
### main stream
output.icecast(host='haack.oslobass.no', port=8000, user="source", password="aicuV3eeboh9u",
  mount="bass.mp3",
	name='Oslo Bass Radio',
 	description='Oslo Bass Radio',
 	url='http://oslobass.no',
	format="audio/mpeg",
	encoding="UTF-8",
	genre="Bass",
	%mp3(bitrate=192,id3v2=true),
input)
output.icecast(host='haack.oslobass.no', port=8000, user="source", password="aicuV3eeboh9u",
  mount="oslobass",
	name='Oslo Bass Radio',
 	description='Oslo Bass Radio',
 	url='http://oslobass.no',
	format="audio/mpeg",
	encoding="UTF-8",
	genre="Bass",
	%mp3(bitrate=192,id3v2=true),
input)
output.icecast(host='haack.oslobass.no', port=8000, user="source", password="aicuV3eeboh9u",
   mount="bass_lofi.mp3",
	name='Oslo Bass Radio',
 	description='Oslo Bass Radio; lofi edition',
 	url='http://oslobass.no',
	format="audio/mpeg",
	encoding="UTF-8",
	genre="Bass",
	%mp3(bitrate=64,stereo=false),
mean(input))
output.icecast(host='haack.oslobass.no', port=8000, user="source", password="aicuV3eeboh9u", 
  mount="bass_hifi.mp3",
	name='Oslo Bass Radio',
 	description='Oslo Bass Radio; hifi edition',
 	url='http://oslobass.no',
	format="audio/mpeg",
	encoding="UTF-8",
	genre="Bass",
	%mp3.vbr(id3v2=true,quality=1),
input)
output.icecast(host='haack.oslobass.no', port=8000, user="source", password="aicuV3eeboh9u",
  mount="bass_flac.ogg",
	name='Oslo Bass Radio',
 	description='Oslo Bass Radio; flac edition',
 	url='http://oslobass.no',
	format="audio/mpeg",
	encoding="UTF-8",
	genre="Bass",
	%ogg(%flac(samplerate=44100, channels=2, compression=5, bits_per_sample=16)),
input)
# delia streams were only here till krav got a grip on dns

# .. FILE OUTPUT
output.file(
  append=true,
  reopen_when={0m0s},
  %mp3(bitrate=64),"/srv/rec/tonify-%Y-%m-%d-%H-%M-%S.mp3",
input)

# .. OGG ICE OUTPUT
output.icecast(host='localhost', port=8000, user="source", password="aicuV3eeboh9u", mount="dab",
	name='Oslo Bass Radio',
 	description='Oslo Bass Radio',
 	url='http://oslobass.no',
	%wav(header=false), input)

# .. DAB OUTPUT SOCKET
#clock.assign_new(sync=false, [ 
#output.external(id="UTSOCK", 
    #%wav(header=false,channels=2),
     #"socat - UDP-SENDTO:localhost:4222",
     #"nc -u localhost 4222",
#    "resocat - ABSTRACT-SENDTO:dabplus,cool-write,shut-none",
  #input)
#])

#output.alsa(id="ALSA",device="postpro", input)

