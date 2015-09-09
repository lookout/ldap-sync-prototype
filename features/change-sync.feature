Feature: Synchronizing changes
  As an administrator in a company
  In order to lower the operating cost
  I want to be able to sync a user hierarchy from an existing LDAP directory
  So I can migrate to a cloud solution with Conjur
  While still using existing tools to administer some of it

  Scenario: Removing a user from a group
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
      gidNumber: <gids[admins]>
      objectClass: posixGroup
      objectClass: top
      memberUid: alice
      """
    And I successfully sync
    Then the role "user:<prefix>-alice" should exist
    And it should be a member of "group:<prefix>-admins"
    And the role "user:<prefix>-bob" should exist
    And it should not be a member of "group:<prefix>-admins"

    Then the LDAP database changes to
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
    When I successfully sync
    Then the role "user:<prefix>-alice" should exist
    And it should not be a member of "group:<prefix>-admins"
    And the role "user:<prefix>-bob" should exist
    And it should be a member of "group:<prefix>-admins"
