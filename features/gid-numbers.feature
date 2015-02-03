Feature: LDAP gidNumbers are imported to Conjur groups
  As an organization using LDAP and Conjur
  I want imported Conjur groups to retain the LDAP gid number
  
  Scenario: LDAP gidNumbers are preserved by conjur-ldap-sync
    Given an LDAP database with:
    """
      dn: cn=users,dc=conjur,dc=net
      cn: users
      gidNumber: <gids[users]>
      objectClass: posixGroup
      objectClass: top
    """
    And I successfully sync
    Then a group named "<prefix>-users" exists and has the gid for "users"