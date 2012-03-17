git clone git://github.com/comotion/hangover
apt-get install luarocks zlib1g-dev
luarocks install orbit

wget http://fallabs.com/tokyocabinet/tokyocabinet-1.4.47.tar.gz -O tokyo.tgz
tar xvf tokyo.tgz
wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz

wget http://fallabs.com/tokyocabinet/luapkg/tokyocabinet-lua-1.10.tar.gz -O - | tar xvf -
cd tokyo*
./configure
make
make install
