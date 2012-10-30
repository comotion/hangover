#!/bin/sh
#git clone git://github.com/comotion/hangover
os=`uname -o`
olddir=`pwd`
mkdir -p inst
cd inst

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
	*Linux)
		dist=`lsb_release -si`
		case $dist in
			Debian|Ubuntu)
				apt-get install luarocks zlib1g-dev liquidsoap libbz2-dev libssl-dev
				apt-get install liquidsoap-plugin-lame
				# somethings wrong with the debian headers
				#apt-get install tokyocabinet-bin libtokyocabinet-dev

				#[ -d bzip2-1.0.6 ] || wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz -qO - | tar xzf -
				#cd bzip2-* 
				#make && make install
				#cd -

				[ -d tokyocabinet-1.4.47 ] || wget http://fallabs.com/tokyocabinet/tokyocabinet-1.4.47.tar.gz -qO - | tar xzf -
				cd tokyocabinet-1.4.47 && ./configure && make ;make install
				cd -
            [ -d tokyotyrant-1.1.41 ] || wget http://fallabs.com/tokyotyrant/tokyotyrant-1.1.41.tar.gz -qO - | tar xzf -
            cd tokyotyrant-1.1.41 && ./configure --enable-lua && make
            make install
            cd -
				[ -d tokyocabinet-lua-1.10 ] || wget http://fallabs.com/tokyocabinet/luapkg/tokyocabinet-lua-1.10.tar.gz -qO - | tar xzf -
				cd tokyocabinet-lua*
				./configure && make
				make install
				cd -
				;;
			*)
				echo "What is this $os $dist ??"
				echo "You'll need to install zlib, and tokyocabinet your own damn self.. and patch setup.sh to do this from now on!"
				;;
		esac

esac

for module in orbit lua-cjson lua-iconv luacrypto struct
do 
   luarocks install $module
done
# until I can get this rockified
[ -d $olddir/web/lib/lamt ] && cd $olddir/web/lib && git clone git://github.com/comotion/lamt

# patch orbit
sed -i 's/\[\%w_\]/[%_w]/g' /usr/local/share/lua/5.1/orbit/model.lua

cd $olddir/web

