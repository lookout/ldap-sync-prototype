Feature: LDAP roles can be imported without their uidNumbers or gidNumbers
  As an organization using Conjur and LDAP
  That has many existing Conjur roles
  In order to avoid having to massively modify my LDAP database
  I want to allow Conjur to generate uids and gids instead of importing them from LDAP

  Scenario: When I give the "--no-ldap-ids" option, roles are not imported with their LDAP ids
    # Note that Conjur won't generate uidnumbers < 1100 so we just
    # have to verify that the "imposible" ids below aren't imported
    Given I initially have an LDAP database with:
      """
        dn: uid=alice,dc=conjur,dc=net
        cn: Alice
        uid: alice
        uidNumber: 777
        gidNumber: 666
        homeDirectory: /home/alice
        objectClass: posixAccount
        objectClass: top

        dn: uid=bob,dc=conjur,dc=net
        cn: Bob
        uid: bob
        uidNumber: 999
        gidNumber: 666
        homeDirectory: /home/bob
        objectClass: posixAccount
        objectClass: top

        dn: cn=users,dc=conjur,dc=net
        cn: users
        gidNumber: 666
        objectClass: posixGroup
        objectClass: top

        dn: cn=admins,dc=conjur,dc=net
        cn: admins
        gidNumber: 111
        objectClass: posixGroup
        objectClass: top
        memberUid: bob
      """
    When I successfully sync with options "--no-ldap-ids"
    Then a user named "<prefix>-alice" exists and does not have uid 777
    And  a user named "<prefix>-bob" exists and does not have uid 999
    And a group named "<prefix>-users" exists and does not have gid 666
    And a group named "<prefix>-admins" exists and does not have gid 111
