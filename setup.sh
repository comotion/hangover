#!/bin/sh
#git clone git://github.com/comotion/hangover
os=`uname -o`

case $os in
	*BSD)
		pkg_add -r git gmake
		cd /usr/ports/lang/lua && make && make install
    cd /usr/ports/audio/liquidsoap && make && make install
		cd /usr/src && [ -d luarocks ] || 
	 		# git clone git://github.com/keplerproject/luarocks.git
			# until they merge my pull request
	 		git clone git://github.com/comotion/luarocks.git

		cd luarocks && ./configure --with-lua-include=/usr/local/include/lua51 && make && make install
		cd -
    [ -d tokyocabinet-1.4.47 ] || wget http://fallabs.com/tokyocabinet/tokyocabinet-1.4.47.tar.gz -qO - | tar xzf -
    cd tokyocabinet-1.4.47 && ./configure && make ;make install
    cd -
		[ -d tokyocabinet-lua-1.10 ] || wget http://fallabs.com/tokyocabinet/luapkg/tokyocabinet-lua-1.10.tar.gz -qO - | tar xzf -
		cd tokyocabinet-lua*
		./configure CFLAGS='-I/usr/local/include/lua51 -I/usr/local/include -std=c99 -fPIC'
		make CFLAGS='-I/usr/local/include/lua51 -I/usr/local/include -std=c99 -fPIC'
		make install
		cd -
		;;
	Linux)
		dist=`lsb_release -si`
		case $dist in
			Debian|Ubuntu)
				apt-get install luarocks zlib1g-dev liquidsoap liquidsoap-plugin-lame
				# somethings wrong with the debian headers
				#apt-get install tokyocabinet-bin libtokyocabinet-dev

				[ -d bzip2-1.0.6 ] || wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz -qO - | tar xzf -
				cd bzip2-* 
				make && make install
				cd -

				[ -d tokyocabinet-1.4.47 ] || wget http://fallabs.com/tokyocabinet/tokyocabinet-1.4.47.tar.gz -qO - | tar xzf -
				cd tokyocabinet-1.4.47 && ./configure && make ;make install
				cd -
				;;
			*)
				echo "What is this $os $dist ??"
				echo "You'll need to install zlib, and tokyocabinet your own damn self.. and patch setup.sh to do this from now on!"
				;;
		esac

esac
luarocks install orbit
luarocks install lua-cjson

# patch orbit
sed -i 's/\[\%w_\]/[%_w]/g' /usr/local/share/lua/5.1/orbit/model.lua



cd web
#[ ! -d sabot ] && git clone git://github.com/comotion/sabot || ( cd sabot && git pull )
