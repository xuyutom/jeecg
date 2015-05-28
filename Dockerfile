FROM centos:centos6
MAINTAINER Guuuo <im@kuo.io>

#install tools
RUN yum -y update; yum clean all
RUN yum install -y wget unzip tar git; yum clean all

#install supervisor
RUN yum install -y python-setuptools; yum clean all
RUN easy_install supervisor
RUN mkdir -p /var/log/supervisor

#install httpd
RUN yum -y install httpd; yum clean all

#config httpd
RUN mkdir -p /data
ADD conf/httpd/wwwroot /data/wwwroot
ADD conf/httpd/wwwconf /data/wwwconf
ADD conf/httpd/httpd.conf /etc/httpd/conf/httpd.conf

#install jdk
ENV JAVA_VERSION 8u45
ENV BUILD_VERSION b14
RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm
RUN yum -y install /tmp/jdk-8-linux-x64.rpm
RUN rm -rf /tmp/jdk-8-linux-x64.rpm
RUN alternatives --install /usr/bin/java jar /usr/java/latest/bin/java 200000
RUN alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 200000
RUN alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
ENV JAVA_HOME /usr/java/latest

#install tomcat
ENV TOMCAT_VERSION 7.0.62
RUN wget http://mirrors.cnnic.cn/apache/tomcat/tomcat-7/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.zip -O /tmp/tomcat.zip
RUN unzip /tmp/tomcat.zip -d /tmp/
RUN rm -rf /tmp/tomcat.zip
RUN mkdir -p /data
RUN mv /tmp/apache-tomcat-$TOMCAT_VERSION /data/tomcat
RUN chmod 777 /data/tomcat/bin/*.sh
ADD conf/tomcat/tomcat-users.xml /data/tomcat/conf/tomcat-users.xml

#install maven
ENV MAVEN_VERSION 3.2.5
RUN wget http://www.eu.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz -O /tmp/maven.tar.gz
RUN tar -xvf /tmp/maven.tar.gz -C /tmp/
RUN rm -rf /tmp/maven.tar.gz
RUN mv /tmp/apache-maven-$MAVEN_VERSION /data/maven
RUN ln -s /data/maven/bin/mvn /usr/bin/mvn
RUN mkdir -p /root/.m2
ENV MAVEN_HOME /data/maven

# get src & package
RUN mkdir -p /data/app
RUN git clone https://github.com/Guuuo/javaweb-hello-world.git /data/app/hello-world
RUN cd /data/app/hello-world; mvn package
RUN cp /data/app/hello-world/target/hello-world.war /data/tomcat/webapps/hello-world.war
RUN rm -rf /data/app

#config supervisor
ADD conf/supervisor/supervisord.conf /etc/supervisord.conf
ADD conf/supervisor/supervisord_tomcat.sh /data/tomcat/bin/supervisord_tomcat.sh
RUN chmod +x /data/tomcat/bin/supervisord_tomcat.sh

EXPOSE 80

CMD ["supervisord", "-n"]
