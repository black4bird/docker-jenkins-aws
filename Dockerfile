FROM ubuntu:latest

MAINTAINER CI&T-KO-TEAM

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV JENKINS_HOME /var/jenkins_home/

RUN apt-get update \
 && apt-get install -y wget git curl zip make subversion ruby-full python2.7 openjdk-7-jdk maven mysql-client dos2unix \
 && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs
RUN gem install sass

RUN ln -sf -T /usr/bin/python2.7 /usr/bin/python \
 && mkdir -p /tmp/installawscli \
 && cd /tmp/installawscli \
 && curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
 && unzip awscli-bundle.zip \
 && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
 && rm -rf /tmp/installawscli

RUN mkdir /usr/share/jenkins/
RUN useradd -d /home/jenkins -m -s /bin/bash jenkins

ADD batch-install-jenkins-plugins.sh /usr/local/bin/batch-install-jenkins-plugins.sh
ADD init.groovy /tmp/WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy

RUN usermod -m -d "$JENKINS_HOME" jenkins && chown -R jenkins "$JENKINS_HOME"
VOLUME /var/jenkins_home/

# for main web interface and attached slave agents:
EXPOSE 8080 50000

ADD jenkins.sh /usr/local/bin/jenkins.sh

ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

# Let you to use a custom maven configuration 
ONBUILD ADD settings.xml /usr/share/maven/conf/settings.xml

# To configure aws-cli
ONBUILD ADD config /var/jenkins_home/.aws/config
ONBUILD ADD credentials /var/jenkins_home/.aws/credentials 

# To install a set of jenkins plugins
ONBUILD ADD okplugins.list /tmp/okplugins.list
ONBUILD ADD jenkins.version /tmp/jenkins.version

# Downloading custom plugins and jenkins. Putting custom plugins into jenkins.war
ONBUILD RUN mkdir -p /tmp/WEB-INF/plugins \
 && batch-install-jenkins-plugins.sh -p /tmp/okplugins.list -d /tmp/WEB-INF/plugins \
 && export JENKINS_VERSION=`cat /tmp/jenkins.version` && rm -f /tmp/jenkins.version \
 && curl -L http://updates.jenkins-ci.org/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
 && cd /tmp \
 && zip -g /usr/share/jenkins/jenkins.war WEB-INF/*/* \
 && rm -rf /tmp/WEB-INF 

ONBUILD USER jenkins 
