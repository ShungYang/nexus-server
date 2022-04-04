FROM sfcs-docker.mic.com.tw:8082/sonatype/nexus3:3.32.0
LABEL name=sfcs-nexus3 \
    version=1.0.0 \
    description="MiTAC Nexus3 with SSL Certificate" \
    author=shawn.yang
EXPOSE 8081 8082 8083 8443

COPY build-files/your_ssl_certificate.jks /opt/sonatype/nexus/etc/ssl/
COPY build-files/nexus.properties /nexus-data/etc/
COPY build-files/jetty-https.xml /opt/sonatype/nexus/etc/jetty/