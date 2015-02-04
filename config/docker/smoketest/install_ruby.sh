#!/bin/bash

cd /root/installs
latest_ruby="ruby-2.2.0"
latest_ruby_url="http://cache.ruby-lang.org/pub/ruby/2.2/${latest_ruby}.tar.gz"
wget ${latest_ruby_url}
tar -zxf ${latest_ruby}.tar.gz
cd /root/installs/${latest_ruby}
./configure --prefix=/usr/local --enable-shared --disable-install-doc
make
make install
cd /root/installs/${latest_ruby}/ext/readline
/usr/local/bin/ruby extconf.rb
make
make install
cd /root/installs/${latest_ruby}/ext/zlib
/usr/local/bin/ruby extconf.rb
make
make install
cd /root/installs/${latest_ruby}/ext/openssl
export top_srcdir=/root/installs/${latest_ruby}
make
make install
cd /root
rm -rf /root/installs/${latest_ruby}
rm /root/installs/${latest_ruby}.tar.gz
