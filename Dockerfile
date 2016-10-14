FROM java:8
MAINTAINER TenxCloud <dev@tenxcloud.com>

ADD sources.list /etc/apt/sources.list
# Install packages
RUN apt-get update && \
    apt-get install -yq --no-install-recommends wget pwgen ca-certificates && \
    apt-get install -y supervisor vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add maven dependencies
ADD mvn-dependencies /root/.m2/

# Add Maven tool
ENV PATH $PATH:/opt/apache-maven-3.3.9/bin
ADD apache-maven-3.3.9 /opt/apache-maven-3.3.9


# Add Tomcat 8
ENV CATALINA_HOME /tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME
ENV TOMCAT_VERSION 8.0.37
ENV TOMCAT_PASS ''
ENV TOMCAT_USER admin
# ENV TOMCAT_PASS **Random**

ADD tomcat8/ $CATALINA_HOME
RUN rm bin/*.bat


# Install ssh
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server pwgen
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

ENV ROOT_PASS ''
ENV AUTHORIZED_KEYS **None**

# ADD scripts
ADD run.sh /run.sh
ADD set_root_pw.sh /set_root_pw.sh
ADD create_tomcat_admin_user.sh /create_tomcat_admin_user.sh
ADD start-sshd.sh /start-sshd.sh
ADD start-tomcat.sh /start-tomcat.sh
RUN chmod 755 /*.sh
ADD supervisord-sshd.conf /etc/supervisor/conf.d/supervisord-sshd.conf
ADD supervisord-tomcat.conf /etc/supervisor/conf.d/supervisord-tomcat.conf

# Add volumes for App
VOLUME ["/tomcat/webapps"]
VOLUME ["/app"]
WORKDIR /app

# expose ports
EXPOSE 8080 22

CMD ["/run.sh"]
