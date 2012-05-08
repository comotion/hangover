#git clone git://github.com/comotion/hangover
apt-get install luarocks zlib1g-dev
luarocks install orbit
luarocks install lua-cjson

# patch orbit
sed -i 's/\[\%w_\]/[%_w]/g' /usr/local/share/lua/5.1/orbit/model.lua

# somethings wrong with the debian headers
#apt-get install tokyocabinet-bin libtokyocabinet-dev
[ -d bzip2-1.0.6 ] || wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz -qO - | tar xzf -
cd bzip2-* 
make && make install
cd -

[ -d tokyocabinet-1.4.47 ] || wget http://fallabs.com/tokyocabinet/tokyocabinet-1.4.47.tar.gz -qO - | tar xzf -
cd tokyocabinet-1.4.47 && ./configure && make ;make install
cd -


[ -d tokyocabinet-lua-1.10 ] || wget http://fallabs.com/tokyocabinet/luapkg/tokyocabinet-lua-1.10.tar.gz -qO - | tar xzf -
cd tokyocabinet-lua*
./configure && make && make install
cd -
cd web
#[ ! -d sabot ] && git clone git://github.com/comotion/sabot || ( cd sabot && git pull )
