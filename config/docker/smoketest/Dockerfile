#You must create the rsa public/private keypair smoketester_id_rsa in this directory
# and export smoketester_id_rsa.pub to gitorious for this to work

FROM centos:centos6
MAINTAINER Darin London <darin.london@duke.edu>

RUN ["/usr/sbin/userdel", "ftp"]
RUN ["/usr/sbin/groupadd", "-g", "50", "staff"]
RUN ["/usr/sbin/useradd", "-N", "-u", "1000", "-g", "50", "smoketester"]

RUN ["/usr/bin/yum", "clean", "all"]
RUN ["/usr/bin/yum", "distro-sync", "-q", "-y", "--nogpgcheck"]
RUN ["/usr/bin/yum", "update", "-q", "-y","--nogpgcheck"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "gcc","gcc-c++", "glibc-static", "which", "zlib-devel", "readline-devel", "libcurl-devel", "tar", "patch"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "openssl", "openssl-devel"]
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "unzip", "bzip2", "wget", "git"]

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

#sqlite
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "sqlite", "sqlite-devel"]

#miscellaneous
RUN ["/usr/bin/yum", "install", "-y", "--nogpgcheck", "nodejs", "git", "libxml2", "libxml2-devel", "libxslt", "libxslt-devel"]

RUN ["mkdir", "-p", "/home/smoketester/.ssh"]
ADD smoketester_id_rsa /home/smoketester/.ssh/id_rsa
ADD ssh_config /home/smoketester/.ssh/config
RUN ["chown", "-R", "smoketester:staff", "/home/smoketester/.ssh"]

ADD smoketest.sh /usr/local/bin/smoketest.sh
RUN ["chmod", "777", "/usr/local/bin/smoketest.sh"]

WORKDIR /home/smoketester
USER smoketester
CMD ["/usr/local/bin/smoketest.sh"]
