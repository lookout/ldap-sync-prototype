FROM ruby:2.0
MAINTAINER Conjur Inc

# Need to install ldap headers and libs for ldap gems.  
RUN apt-get update && apt-get install -y libldap-2.4-2 libldap2-dev libsasl2-dev

ENV PATH=/opt/ldap-sync/bin:$PATH
WORKDIR /opt/ldap-sync

ADD . /opt/ldap-sync/

RUN cd /opt/ldap-sync && bundle install --binstubs

ENTRYPOINT ["conjur-ldap-sync"]
