# base image with utility
FROM ruby:2.0
MAINTAINER Conjur Inc

ADD . /opt/ldap-sync/
WORKDIR /opt/ldap-sync

# Need to install ldap headers and libs for ldap gems
RUN apt-get update
RUN apt-get install -y libldap-2.4-2 libldap2-dev libsasl2-dev


RUN cd /opt/ldap-sync && bundle install --binstubs

ENTRYPOINT ["bundle", "exec", "rake", "test"]
