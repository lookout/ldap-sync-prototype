Feature: Roles are owned by the role specified by --owner
  As a Conjur user
  In order to manage roles imported from my directory
  I want to assign ownership of all roles imported to a particular role.

  Background:
    Given I initially have an LDAP database with:
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
      gidNumber: <gids[admin]>
      objectClass: posixGroup
      objectClass: top
      memberUid: bob
      """

  Scenario: Roles are owned by the logged in role when no --owner option  is given
    When I successfully sync
    Then role "user:<prefix>-alice" should exist
    And it should be owned by "service:<prefix>"
    And the role "group:<prefix>-admins" should exist
    And it should be owned by "service:<prefix>"

  Scenario: Roles are owned by the role given by --owner
    Given a role named "user:<prefix>-ldap-agent"
    When I successfully sync with options "--owner user:<prefix>-ldap-agent"
    Then the role "user:<prefix>-alice" should exist
    And it should be owned by "user:<prefix>-ldap-agent"
    And the role "group:<prefix>-admins" should exist
    And it should be owned by "user:<prefix>-ldap-agent"