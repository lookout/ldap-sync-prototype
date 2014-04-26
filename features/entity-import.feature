Feature: Entity import
  In order to integrate with some existing systems
  I want to have the relevant entities from that directory mirrored in Conjur
  So I can administer some Conjur users in an external directory

  Scenario: RFC 2307 schema
    Given LDAP database with:
      """
      dn: uid=alice,ou=People,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: 36
      gidNumber: 1019
      homeDirectory: /home/alice

      dn: uid=bob,ou=People,dc=conjur,dc=net
      cn: Bob
      uid: bob
      uidNumber: 37
      gidNumber: 1019
      homeDirectory: /home/bob

      dn: cn=users,ou=Group,dc=conjur,dc=net
      cn: users
      gidNumber: 1019
      objectClass: posixGroup
      objectClass: top

      dn: cn=admins,ou=Group,dc=conjur,dc=net
      cn: admins
      gidNumber: 985
      objectClass: posixGroup
      objectClass: top
      memberUid: bob
      """
    When I run "conjur-ldap-sync"
    Then role "ldap-user:alice" should exist
    And it should be a member of "ldap-group:users"
    But not "ldap-group:admins"
    And role "ldap-user:bob" should exist
    And it should be a member of "ldap-group:users"
    And also to "ldap-group:admins"
