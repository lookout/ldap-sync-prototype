# base image with utility
FROM ruby:2.0
MAINTAINER Conjur Inc


# Need to install ldap headers and libs for ldap gems.  Ladle uses
# java to run an ldap server.
RUN apt-get update && apt-get install -y libldap-2.4-2 libldap2-dev libsasl2-dev openjdk-7-jre

ADD . /opt/ldap-sync/
WORKDIR /opt/ldap-sync


RUN cd /opt/ldap-sync && bundle install --binstubs

ENTRYPOINT ["bundle", "exec", "rake","--trace", "test"]
