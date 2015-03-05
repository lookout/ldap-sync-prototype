# Conjur::Ldap::Sync

Synchronizes users and groups from an LDAP server to a hierarchy of roles in Conjur.

## Installation

    $ gem install conjur-ldap-sync

## Usage

- Create a `user` role for the service.
- Create an `ldap.conf` with LDAP connection settings.
- Set up an environment as described below.
- run conjur-ldap-sync (possibly from a crontab).

## Configuration

conjur-ldap-sync currently can only be configured via environment variables.

### LDAP

The easiest way to configure the LDAP side is to create a configuration file such as:
```
SSL off # NOTE: due to a quirk this should come first
URI ldap://localhost:3897
BASE dc=conjur,dc=net
```
and point `LDAPCONF` to its path.

For other options (such as using environment variables directly), please consult
[Treequel documentation](http://rubydoc.info/gems/treequel/Treequel#directory_from_config-class_method).

### Conjur

The `conjur-ldap-sync` program must be run with a Conjur identity that can create
and modify roles.  This identity will typically be a user, but could also be 
a host.  We'll refer to this user as the **service**.

To allow conjur-ldap-sync to connect to Conjur, make sure `CONJUR_USERNAME`
and `CONJUR_API_KEY` environment variables correspond to a pre-created role
dedicated for this purpose.  You must also set the `CONJUR_APPLIANCE_URL` and
`CONJUR_ACCOUNT` variables appropriately.  These values **are not** loaded from
`.conjurrc`.

## Operation

conjur-ldap-sync replicates user and group structure from an upstream LDAP server in Conjur.

It maps posixAccount and posixGroup objects (as defined by RFC 2307) respectively to Conjur
users and groups, with group roles granted to appropriate users.  All created roles are granted
to either the service role or the role specficied by the `--owner OWNER` option.

Note that if the owner role is specified, the service role must be a member of the owner role.

The `conjur-ldap-sync` command accepts the following options:

    --owner OWNER                Role that will own all groups, users, and variables created
    --save-api-keys              When present, passwords will be saved to variables

The `--save-api-keys` is off by default, but recommended if you want to allow created roles to login to
Conjur.



## Running the Tests

The tests expect the following variables to be defined in the environment:

 * `CONJUR_APPLIANCE_URL`: Url of the appliance used by the features, e.g. `https://conjur.mycompany.com/api`
 * `CONJUR_USERNAME`: The username to use when setting up test roles.
 * `CONJUR_API_KEY`:  The api key or password for the user.
 * `CONJUR_ACCOUNT`: Your Conjur account.

To run the tests, run this in the project directory:

```
$ rake test
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/conjur-ldap-sync/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
