Feature: Entity import
  As an administrator in a company
  In order to lower the operating cost
  I want to be able to import user hierarchy from an existing LDAP directory
  So I can migrate to a cloud solution with Conjur
  Without having to recreate all the data from scratch

  Scenario: RFC 2307 schema
    Given LDAP database with:
      """
      dn: uid=alice,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: 36
      gidNumber: 1019
      homeDirectory: /home/alice
      objectClass: posixAccount
      objectClass: top

      dn: uid=bob,dc=conjur,dc=net
      cn: Bob
      uid: bob
      uidNumber: 37
      gidNumber: 1019
      homeDirectory: /home/bob
      objectClass: posixAccount
      objectClass: top

      dn: cn=users,dc=conjur,dc=net
      cn: users
      gidNumber: 1019
      objectClass: posixGroup
      objectClass: top

      dn: cn=admins,dc=conjur,dc=net
      cn: admins
      gidNumber: 985
      objectClass: posixGroup
      objectClass: top
      memberUid: bob
      """
    When I successfully sync
    Then role "user:<prefix>-alice" should exist
    And it should be a member of "group:<prefix>-users"
    But it should not be a member of "group:<prefix>-admins"
    And role "user:<prefix>-bob" should exist
    And it should be a member of "group:<prefix>-users"
    And it should be a member of "group:<prefix>-admins"
