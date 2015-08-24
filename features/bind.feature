Feature: I can bind to the server
  As a Conjur user
  With a secure LDAP service
  I want to be able to bind using a password

  Scenario: I can bind using command line options
    Given I initially have an LDAP database with:
      """
      dn: uid=ldapAdmin,dc=conjur,dc=net
      cn: LDAP Admin
      uid: ldapAdmin
      sn: Whatever
      uidNumber: <uids[ldapAdmin]>
      gidNumber: <gids[ldapAdmins]>
      homeDirectory: /home/ldapADMIN
      objectClass: inetOrgPerson
      objectClass: posixAccount
      # Password is "supersecret" (see bin/ldap-password-hash)
      userpassword: {SHA}p2HOOkXZfkGECniElehacNG7OBU=

      # Somebody else
      dn: uid=bob,dc=conjur,dc=net
      cn: Bob
      uid: bob
      uidNumber <uids[bob]>
      objectClass: posixAccount
      objectClass: top
      """
    Then I can successfully sync with options "--bind-dn 'uid=ldapAdmin,dc=conjur,dc=net' --bind-password supersecret"
    But I can not sync with options "--bind-dn 'uid=wrongDN,dc=conjur,dc=net' --bind-password supersecret"
    And I can not sync with options "--bind-dn 'uid=ldapAdmin,dc=conjur,dc=net' --bind-password wrongpass"
