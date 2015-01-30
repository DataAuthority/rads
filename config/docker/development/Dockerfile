FROM centos:centos6
MAINTAINER Darin London <darin.london@duke.edu>

RUN ["/usr/sbin/userdel", "ftp"]
RUN ["/usr/sbin/groupadd", "-g", "50", "staff"]
RUN ["/usr/sbin/useradd", "-N", "-u", "1000", "-g", "50", "londo003"]

RUN ["/usr/bin/yum", "clean", "all"]
RUN ["/usr/bin/yum", "distro-sync", "-q", "-y", "--nogpgcheck"]
RUN ["/usr/bin/yum", "update", "-q", "-y","--nogpgcheck"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "gcc","gcc-c++", "glibc-static", "which", "zlib-devel", "readline-devel", "libcurl-devel", "tar", "patch"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "openssl", "openssl-devel"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "unzip", "bzip2", "wget"]

#shellshocked!
RUN ["/usr/bin/yum", "update", "-y", "--nogpgcheck", "bash"]

#epel
RUN ["mkdir", "-p", "/root/installs"]
WORKDIR /root/installs
ADD install_epel.sh /root/installs/install_epel.sh
RUN ["chmod", "u+x", "/root/installs/install_epel.sh"]
RUN ["/root/installs/install_epel.sh"]

#ruby
ADD install_ruby.sh /root/installs/install_ruby.sh
RUN ["chmod", "u+x", "/root/installs/install_ruby.sh"]
RUN ["/root/installs/install_ruby.sh"]
RUN ["/usr/local/bin/gem", "install", "--no-rdoc", "--no-ri", "bundler"]
RUN ["/usr/local/bin/gem", "install", "--no-rdoc", "--no-ri", "rails"]

# apache used for mod_xsendfile
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "httpd", "httpd-devel", "apr-devel", "apr-util-devel", "mod_xsendfile", "mod_ssl"]
ADD mod_xsendfile.conf /etc/httpd/conf.d/mod_xsendfile.conf
ADD ssl.conf /etc/httpd/conf.d/ssl.conf

#passenger
RUN ["/usr/local/bin/gem", "install", "--no-rdoc", "--no-ri", "passenger"]
RUN ["/usr/local/bin/passenger-install-apache2-module", "--auto"]
ADD install_passenger_conf.rb /root/install_passenger_conf.rb
RUN ["/root/install_passenger_conf.rb"]

#sqlite
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "sqlite", "sqlite-devel"]

#miscellaneous
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "nodejs", "git", "libxml2", "libxml2-devel", "libxslt", "libxslt-devel"]

ADD httpd.conf.patch /tmp/httpd.conf.patch
RUN ["patch", "/etc/httpd/conf/httpd.conf", "/tmp/httpd.conf.patch"]
ADD rads.conf /etc/httpd/conf.d/rads.conf
EXPOSE 443
WORKDIR /var/www/app
CMD ["/usr/sbin/httpd","-DFOREGROUND","-DSSL"]
