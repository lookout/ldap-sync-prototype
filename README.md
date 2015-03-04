# Conjur::Ldap::Sync

Synchronizes users and groups from an LDAP server to a hierarchy of roles in Conjur.

## Installation

    $ gem install conjur-ldap-sync

## Usage

- Create a role for the service.
- Create ldaprc with LDAP connection settings.
- Run (possibly from a crontab).

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

To allow conjur-ldap-sync to connect to Conjur, make sure `CONJUR_USERNAME`
and `CONJUR_API_KEY` environment variables correspond to a pre-created role
dedicated for this purpose.

The role name will be used as a prefix for created roles; eg. conjur-ldap-sync with
`CONJUR_USERNAME=service/my-directory` will create roles such as
`ldap-user:my-directory/alice` and `ldap-group:my-directory/legion`.

## Operation

conjur-ldap-sync replicates user and group structure from an upstream LDAP server in Conjur.

It maps posixAccount and posixGroup objects (as defined by RFC 2307) respectively to
`*:ldap-user:<prefix>/<uid>` and `*:ldap-group:<prefix>/<cn>` Conjur roles, with
group roles granted to appropriate users. Prefix is taken from the service user name
and is intended to allow several LDAP syncers to coexist in a single Conjur system.

Mapping posixAccount and posixGroup types to generic ldap-user/group role kinds
allows transparently extending the syncer to handle different LDAP schemas
(eg. ActiveDirectory).

It's the system administrator's responsibility to tie (through appropriate role grants)
the ldap hierarchy to existing Conjur entities. Note it's possible to create some utilities to
facilitate this process according to business needs; some of the common use cases may
be automated in the future.

(Not implemented:)
Running conjur-ldap-sync again will change the Conjur representation of the LDAP entries
to reflect any changes made since the last run. Because it's not possible to remove entities in Conjur,
deletion will cause any and all role grants on the corresponding entity to be revoked.

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
