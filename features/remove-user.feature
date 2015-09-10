Feature: User removal works as expected.
  This is a regression test based on a bug encountered by a customer.

  Scenario: Users removed by filter are removed successfully
    Given I initially have an LDAP database with:
      """
      dn: uid=alice,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: <uids[alice]>
      gidNumber: <gids[users]>
      homeDirectory: /home/alice
      objectClass: posixAccount
      objectClass: shadowAccount
      objectClass: top
      shadowFlag: 512

      dn: cn=devs,dc=conjur,dc=net
      cn: devs
      gidNumber: <gids[devs]>
      objectClass: posixGroup
      objectClass: top
      memberUid: alice

      dn: cn=users,dc=conjur,dc=net
      cn: users
      gidNumber: <gids[users]>
      objectClass: posixGroup
      objectClass: top
      """
    And I successfully sync with options "--user-filter '(&(objectClass=posixAccount)(shadowFlag=512))'"
    Then the role "user:<prefix>-alice" should exist
    And it should be a member of "group:<prefix>-users"
    And it should be a member of "group:<prefix>-devs"
    When the LDAP database changes to
      """
      dn: uid=alice,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: <uids[alice]>
      gidNumber: <gids[users]>
      homeDirectory: /home/alice
      objectClass: posixAccount
      objectClass: shadowAccount
      objectClass: top
      shadowFlag: 514

      dn: cn=devs,dc=conjur,dc=net
      cn: devs
      gidNumber: <gids[devs]>
      objectClass: posixGroup
      objectClass: top
      memberUid: alice

      dn: cn=users,dc=conjur,dc=net
      cn: users
      gidNumber: <gids[users]>
      objectClass: posixGroup
      objectClass: top
      memberUid: alice
      """
    And I successfully sync with options "--user-filter '(&(objectClass=posixAccount)(shadowFlag=512))'"
    Then the role "user:<prefix>-alice" should exist
    But it should not be a member of "group:<prefix>-users"
    And it should not be a member of "group:<prefix>-devs"
