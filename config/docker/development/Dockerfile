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
WORKDIR /root
RUN ["wget", "http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"]
RUN ["rpm", "-ivh", "/root/epel-release-6-8.noarch.rpm"]
RUN ["rm", "/root/epel-release-6-8.noarch.rpm"]

#ruby
ADD install_ruby.sh /root/install_ruby.sh
RUN ["chmod", "u+x", "/root/install_ruby.sh"]
RUN ["/root/install_ruby.sh"]
RUN ["/usr/local/bin/gem", "install", "--no-rdoc", "--no-ri", "bundler"]
RUN ["/usr/local/bin/gem", "install", "--no-rdoc", "--no-ri", "rails"]

# apache
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "httpd", "httpd-devel", "apr-devel", "apr-util-devel", "mod_xsendfile", "mod_ssl"]
ADD mod_xsendfile.conf /etc/httpd/conf.d/mod_xsendfile.conf
ADD ssl.conf /etc/httpd/conf.d/ssl.conf

# shibboleth
ADD duke-el-shib2.repo /etc/yum.repos.d/duke-el-shib2.repo
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "shibboleth"]
ADD etc_shibboleth /etc/shibboleth
ADD shib.conf /etc/httpd/conf.d/shib.conf

#passenger
RUN ["/usr/local/bin/gem", "install", "--no-rdoc", "--no-ri", "passenger"]
RUN ["/usr/local/bin/passenger-install-apache2-module", "--auto"]
ADD install_passenger_conf.rb /root/install_passenger_conf.rb
RUN ["/root/install_passenger_conf.rb"]

#sqlite
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "sqlite", "sqlite-devel"]

#miscellaneous
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "git", "libxml2", "libxml2-devel", "libxslt", "libxslt-devel"]

ADD httpd.conf.patch /tmp/httpd.conf.patch
RUN ["patch", "/etc/httpd/conf/httpd.conf", "/tmp/httpd.conf.patch"]
ADD rads.conf /etc/httpd/conf.d/rads.conf
ADD run.sh /usr/local/bin/run.sh
EXPOSE 443
WORKDIR /var/www/app
CMD ["/usr/local/bin/run.sh"]
