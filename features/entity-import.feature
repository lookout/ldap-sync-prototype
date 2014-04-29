Feature: Entity import
  In order to integrate with some existing systems
  I want to have the relevant entities from that directory mirrored in Conjur
  So I can administer some Conjur users in an external directory

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
    When I successfully run `conjur-ldap-sync`
    Then role "ldap-user:<prefix>/alice" should exist
    And it should be a member of "ldap-group:<prefix>/users"
    But it should not be a member of "ldap-group:<prefix>/admins"
    And role "ldap-user:<prefix>/bob" should exist
    And it should be a member of "ldap-group:<prefix>/users"
    And it should be a member of "ldap-group:<prefix>/admins"
