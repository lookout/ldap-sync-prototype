Feature: Entity annotations
  As an administrator
  I want to be able to create Conjur assets both by importing from LDAP and directly
  I need my LDAP assets to be marked as such

  Background: A simple LDAP database
    Given LDAP database with:
      """
      dn: uid=alice,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: <uids[alice]>
      gidNumber: <gids[users]>
      homeDirectory: /home/alice
      objectClass: posixAccount
      objectClass: top

      dn: uid=bob,dc=conjur,dc=net
      cn: Bob
      uid: bob
      uidNumber: <uids[bob]>
      gidNumber: <gids[users]>
      homeDirectory: /home/bob
      objectClass: posixAccount
      objectClass: top

      dn: cn=users,dc=conjur,dc=net
      cn: users
      gidNumber: <gids[users]>
      objectClass: posixGroup
      objectClass: top

      dn: cn=admins,dc=conjur,dc=net
      cn: admins
      gidNumber: <gids[admins]>
      objectClass: posixGroup
      objectClass: top
      memberUid: bob
      """

  Scenario: Annotations with default options
    When I successfully sync
    Then the resource "user:<prefix>-bob" should have annotation "ldap-sync/source"="ci:service:<prefix>"
    And  the resource "group:<prefix>-users" should have annotation "ldap-sync/source"="ci:service:<prefix>"
    And the resource "user:<prefix>-bob" should have annotation "ldap-sync/upstream-dn"="uid=bob,dc=conjur,dc=net"
    And  the resource "group:<prefix>-users" should have annotation "ldap-sync/upstream-dn"="cn=users,dc=conjur,dc=net"

  Scenario: Annotations specified by options
    When I successfully sync with options "--source-tag 'some-other-source'"
    Then the resource "user:<prefix>-bob" should have annotation "ldap-sync/source"="some-other-source"
    And  the resource "group:<prefix>-users" should have annotation "ldap-sync/source"="some-other-source"
    But the resource "group:<prefix>-users" should have annotation "ldap-sync/upstream-dn"="cn=users,dc=conjur,dc=net"
