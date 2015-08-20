Feature: ldap-sync services only manipulate roles that they created.
  As a user of Conjur and LDAP
  I want to synchronize Conjur and LDAP
  But I do not want to clobber changes made in Conjur

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
      gidNumber: <gids[admins]>
      objectClass: posixGroup
      objectClass: top
      memberUid: bob
      """
    And I successfully sync

  Scenario: Users added through Conjur are not deleted
    When I create a user "<prefix>-from-conjur"
    And I add user "<prefix>-from-conjur" to group "<prefix>-admins"
    And I successfully sync
    Then the role "user:<prefix>-from-conjur" should exist
    And it should be a member of "group:<prefix>-admins"

  Scenario: Groups added through Conjur are not deleted
    When I create a group "<prefix>-from-conjur"
    And I add user "<prefix>-bob" to group "<prefix>-from-conjur"
    And I successfully sync
    Then the role "group:<prefix>-from-conjur" should exist
    And the role "user:<prefix>-bob" should be a member of "group:<prefix>-from-conjur"


