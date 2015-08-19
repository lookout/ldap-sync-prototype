Feature: A report of actions taken is generated
  As an organization using Conjur
  In order to observe the actions and take corrective action for errors
  I want to see a structured record of all actions and errors.

  Scenario: Report of entity import
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
        memberUid: alice
        """

    And I successfully sync
    Then the report should have actions:
       |      tag      |    extra_json                                            |
       | create_user   |  {"user":  "<prefix>-alice"}                             |
       | create_group  |  {"group": "<prefix>-users"}                             |
       | add_member    |  {"group": "<prefix>-users", "user": "<prefix>-alice"}   |
       | create_group  |  {"group": "<prefix>-admins"}                            |
       | add_member    |  {"group": "<prefix>-admins", "user": "<prefix>-alice"}  |
    When the LDAP database changes to
      """
      dn: uid=alice,dc=conjur,dc=net
      cn: Alice
      uid: alice
      uidNumber: <uids[alice]>
      gidNumber: <gids[users]>
      homeDirectory: /home/alice
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
      """
    And I successfully sync
    Then the report should have actions:
      |       tag     |                extra_json                               |
      | remove_member |  {"group": "<prefix>-admins", "user": "<prefix>-alice"} |

  Scenario: Text output format
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
        memberUid: alice
        """

    And I successfully sync with options "--format text"
    Then the report should have text
      """
      create_user: result=success, uid=<uids[alice]>, user=<prefix>-alice
      create_group: gid=<gids[users]>, group=<prefix>-users, result=success
      add_member: group=<prefix>-users, result=success, user=<prefix>-alice
      create_group: gid=<gids[admins]>, group=<prefix>-admins, result=success
      add_member: group=<prefix>-admins, result=success, user=<prefix>-alice
      """