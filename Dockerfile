FROM jboss/keycloak:16.1.1

USER 10000

EXPOSE 8443
EXPOSE 8080

RUN sed -i 's/<socket-binding name="txn-status-manager" port="4713"\/>/<socket-binding name="txn-status-manager" port="4713"\/><socket-binding name="proxy-https" port="443"\/>/g' /opt/jboss/keycloak/standalone/configuration/standalone.xml

ENV PROXY_ADDRESS_FORWARDING true
ENV REDIRECT_SOCKET proxy-https

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]
CMD ["-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]