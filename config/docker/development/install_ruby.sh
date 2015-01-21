#!/bin/bash

cd /root/installs
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz
tar -zxf ruby-2.1.5.tar.gz
cd /root/installs/ruby-2.1.5
./configure --prefix=/usr/local --enable-shared --disable-install-doc
make
make install
cd /root/installs/ruby-2.1.5
/ext/readline
/usr/local/bin/ruby extconf.rb
make
make install
cd /root/installs/ruby-2.1.5
/ext/zlib
/usr/local/bin/ruby extconf.rb
make
make install
cd /root/installs/ruby-2.1.5
/ext/openssl
export top_srcdir=/root/installs/ruby-2.1.5
make
make install
cd /root
rm -rf /root/installs/ruby-2.1.5
rm /root/installs/ruby-2.1.5.tar.gz
