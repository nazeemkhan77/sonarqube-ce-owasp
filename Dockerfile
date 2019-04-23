FROM openjdk:8

ENV SONAR_VERSION=7.7 \
    SONARQUBE_HOME=/opt/sonarqube \
    SQ_DPCHECK_VERSION=1.2.3 \
    SQ_OIDC_VERSION=1.0.4 \
    SQ_BITBUCKET_AUTH_VERSION=1.0 \
    SQ_BITBUCKET_VERSION=1.2.1 \
    # Database configuration
    # Defaults to using H2
    # DEPRECATED. Use -v sonar.jdbc.username=... instead
    # Drop these in the next release, also in the run script
    SONARQUBE_JDBC_USERNAME=sonar \
    SONARQUBE_JDBC_PASSWORD=sonar \
    SONARQUBE_JDBC_URL= 

# Http port
EXPOSE 9000

RUN groupadd -r sonarqube && useradd -r -g sonarqube sonarqube

# grab gosu for easy step-down from root
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && (gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        || gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4) \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN set -x \
    # pub   2048R/D26468DE 2015-05-25
    #       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
    # uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
    # sub   2048R/06855C1D 2015-05-25
    && (gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE \
	    || gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE) \
    && cd /opt \
    && curl -o sonarqube.zip -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip \
    && curl -o sonarqube.zip.asc -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip.asc \
    && gpg --batch --verify sonarqube.zip.asc sonarqube.zip \
    && unzip sonarqube.zip \
    && mv sonarqube-$SONAR_VERSION sonarqube \
    && chown -R sonarqube:sonarqube sonarqube \
    && rm sonarqube.zip* \
    && rm -rf $SONARQUBE_HOME/bin/* \
    && cd  $SONARQUBE_HOME/extensions/plugins/ \
    && wget --no-verbose https://github.com/SonarSecurityCommunity/dependency-check-sonar-plugin/releases/download/$SQ_DPCHECK_VERSION/sonar-dependency-check-plugin-$SQ_DPCHECK_VERSION.jar \
    && wget --no-verbose https://github.com/vaulttec/sonar-auth-oidc/releases/download/v$SQ_OIDC_VERSION/sonar-auth-oidc-plugin-$SQ_OIDC_VERSION.jar \
    && wget --no-verbose https://github.com/SonarSource/sonar-auth-bitbucket/releases/download/$SQ_BITBUCKET_AUTH_VERSION/sonar-auth-bitbucket-plugin-$SQ_BITBUCKET_AUTH_VERSION.jar \
    && wget --no-verbose https://github.com/mibexsoftware/sonar-bitbucket-plugin/releases/download/v$SQ_BITBUCKET_VERSION/sonar-bitbucket-plugin-$SQ_BITBUCKET_VERSION.jar

VOLUME "$SONARQUBE_HOME/data"

WORKDIR $SONARQUBE_HOME
COPY run.sh $SONARQUBE_HOME/bin/
RUN chmod +x $SONARQUBE_HOME/bin/run.sh
USER sonarqube
ENTRYPOINT ["./bin/run.sh"]
