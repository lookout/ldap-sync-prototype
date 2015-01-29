Feature: Saving user credentials to Conjur variables
  As a Conjur user with an existing directory system
  I want to be able to access the api keys of users created by ldap-sync
  So that the users can login to with their api keys

  Background:
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

  Scenario: The current role can access the api key for user 'bob'
    When I successfully sync with options "--save-passwords"
    Then the variable "<prefix>-bob/password" should exist
    And role "service:<prefix>" can execute the variable

  Scenario: The role specified by --owner can access the api key for 'bob'
    Given a role named "service:<prefix>-ldap-agent"
    When I successfully sync with options "--owner service:<prefix>-ldap-agent --save-passwords"
    Then the variable "<prefix>-bob/password" should exist
    And role "service:<prefix>-ldap-agent" can execute the variable

  Scenario: Passwords are not saved when the --save-passwords option is not given
    When I successfully sync
    Then the variable "<prefix>-bob/password" should not exist