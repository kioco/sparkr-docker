FROM centos
MAINTAINER Tetsuo Yamabe

# Timezone settings

RUN echo 'LANG="ja_JP.UTF-8"' > /etc/sysconfig/i18n ;echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock ;cp -a /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Add Epel repository

RUN rpm --import http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/RPM-GPG-KEY-EPEL-6
RUN rpm -Uvh http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm

# Add Remi repository

RUN rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# Add RPM Forge repository

RUN rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
RUN rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm

# Use fastest mirror first, with Japanese repositories

RUN yum install -y yum-plugin-fastestmirror
RUN echo "include_only=.jp" >> /etc/yum/pluginconf.d/fastestmirror.conf

# Misc packages

RUN yum groupinstall -y "Development Tools"
RUN yum --enablerepo=epel install -y rsyslog wget sudo;
RUN yum install -y java-1.7.0-openjdk-devel
RUN yum --enablerepo=rpmforge-extras install -y git

# Fetch and build Spark package

WORKDIR /home/root
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-0.9.1.tgz
RUN tar xvfz spark-0.9.1.tgz
WORKDIR /home/root/spark-0.9.1
RUN sbt/sbt assembly

# Install SparkR

WORKDIR /home/root
RUN yum install -y R
RUN wget http://cran.r-project.org/src/contrib/rJava_0.9-6.tar.gz
RUN R CMD INSTALL rJava_0.9-6.tar.gz
RUN R CMD javareconf
RUN wget http://download2.rstudio.org/rstudio-server-0.98.507-x86_64.rpm
RUN yum install -y --nogpgcheck rstudio-server-0.98.507-x86_64.rpm

RUN yum install -y curl-devel
ADD files/sparkInstall.R /tmp/sparkInstall.R
RUN R --vanilla --slave < /tmp/sparkInstall.R

RUN groupadd rstudio
RUN useradd -g rstudio rstudio
RUN echo rstudio | passwd --stdin rstudio

EXPOSE 8787
CMD /usr/lib/rstudio-server/bin/rserver --server-daemonize 0
