Feature: LDAP gidNumbers are imported to Conjur groups
  As an organization using LDAP and Conjur
  I want imported Conjur groups to retain the LDAP gid number
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
  Scenario: LDAP gidNumbers are preserved by conjur-ldap-sync
    When I successfully sync
    Then a group named "<prefix>-users" exists and has the gid for "users"