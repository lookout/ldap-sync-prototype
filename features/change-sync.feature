Feature: Synchronizing changes
  As an administrator in a company
  In order to lower the operating cost
  I want to be able to sync a user hierarchy from an existing LDAP directory
  So I can migrate to a cloud solution with Conjur
  While still using existing tools to administer some of it

  @wip
  Scenario: Removing a user from a group
    Given I initially have an LDAP database with:
    """
    dn: uid=alice,dc=conjur,dc=net
    cn: Alice
    uid: alice
    uidNumber: 36
    gidNumber: 1019
    homeDirectory: /home/alice
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
    memberUid: alice
    """
    And I successfully run `conjur-ldap-sync`
    Then the role "ldap-user:<prefix>/alice" should exist
    And it should be a member of "ldap-group:<prefix>/admins"

    Then the LDAP database changes to
    """
    dn: uid=alice,dc=conjur,dc=net
    cn: Alice
    uid: alice
    uidNumber: 36
    gidNumber: 1019
    homeDirectory: /home/alice
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
    """
    When I successfully run `conjur-ldap-sync`
    Then it should not be a member of "ldap-group:<prefix>/admins"
