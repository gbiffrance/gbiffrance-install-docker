FROM solr:7.7.2-slim

COPY --chown=solr:solr mycores /opt/solr/server/solr/mycores
COPY --chown=solr:solr solr.xml /opt/solr/server/solr/solr.xml
COPY --chown=solr:solr zoo.cfg /opt/solr/server/solr/zoo.cfg
COPY --chown=solr:solr lib/*.jar /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/
COPY --chown=solr:solr solr.in.sh /etc/default/solr.in.sh
