# Conjur LDAP Sync

Synchronizes users and groups from an upstream LDAP to Conjur [Users](http://developer.conjur.net/reference/services/directory/user) and [Groups](http://developer.conjur.net/reference/services/directory/group).

## Installation

    $ gem install conjur-ldap-sync
    
Note: Installation and operation will soon be changed to Docker.

### Launch from official docker image stored in Conjur repo

    $ docker run --rm -it $CONJUR_DOCKER_REGISTRY/conjurinc/ldap-sync --help

### Building docker image

Makefile contains several targets responsible for the build of base docker image (containing ldap-sync utility) and acceptance docker image, which has tests added to it.

Below is the description of related targets

* build/clean -- deletes build directory (which is `./build`)
* build/base  -- builds base image
* build/test  -- builds additional image with tests
* build/push -- if CONJUR\_DOCKER\_REGISTRY is defined, pushes both types of images to it

## Usage

- Create a Conjur [Host](http://developer.conjur.net/reference/services/directory/host) with sufficient privileges to manage the Conjur users and groups.
- Create an `ldap.conf` with LDAP connection settings.
- Set up an environment as described below.
- run conjur-ldap-sync (possibly from a crontab).

## Configuration

conjur-ldap-sync currently can only be configured via environment variables.

### LDAP

The easiest way to configure the LDAP source is to create a configuration file such as:
```
SSL off # NOTE: due to a quirk this should come first
URI ldap://localhost:3897
BASE dc=conjur,dc=net
```
and point `LDAPCONF` to its path.

For other options (such as using environment variables directly), please consult
[Treequel documentation](http://rubydoc.info/gems/treequel/Treequel#directory_from_config-class_method).

### Conjur

The `conjur-ldap-sync` program must be run with a Conjur Host identity that can create
and modify roles.  We'll refer to this user as the **service**.

To allow conjur-ldap-sync to connect to Conjur, make sure `CONJUR_AUTHN_LOGIN`
and `CONJUR_AUTHN_API_KEY` environment variables correspond to a pre-created role
dedicated for this purpose.  You must also set the `CONJUR_APPLIANCE_URL` and
`CONJUR_ACCOUNT` variables appropriately.  These values **are not** loaded from
`.conjurrc`.

## Operation

conjur-ldap-sync replicates user and group structure from an upstream LDAP server into Conjur.

It maps `posixAccount` and `posixGroup` objects (as defined by RFC 2307) respectively to Conjur
users and groups, with group membership granted to appropriate users.  All created roles are granted
either to the service role or to the role specficied by the `--owner OWNER` option.

Note that if the owner role is specified, the service role must be a member of the owner role.

The `conjur-ldap-sync` command accepts the following options:

    --owner OWNER                Role that will own all groups, users, and variables created
    --save-api-keys              When present, passwords will be saved to variables
    --bind-dn DN                 DN to use for authenticated binds.  If present, --bind-password must also be given.
    --bind-password PASS         Password to use for authenticated binds.  You can also use the environment variable
                                    CONJUR_LDAP_PASSWORD to avoid placing secrets on the command line.
    --format [FORMAT]            Output format for reporting (text, json)
                                     (default: json)
    --mode [MODE]                Flavor of LDAP to expect from the server (posix, active_directory)
                                     (default: posix)
    --group-object-classes [CLASSES] LDAP objectClasses that should be imported as groups
    --user-object-classes [CLASSES] LDAP objectClasses that should be imported as users


The `--save-api-keys` is off by default, but recommended if you want to allow created roles to login to
Conjur.

## LDAP Flavors

Active Directory returns a directory structure that differs from posix (OpenLDAP, Apache DS, OpenDJ, and others) structures.  You can tell ldap-sync to use assume Active Directory structures with `--mode active_directory`.  You can also conrol the records that are selected for groups and users with `--user-object-classes oc1,oc2` and `--group-object-classes oc1,oc2`.

## Reports

In addition to logging various information to the `stderr` (configurable with the `--log-level` option), `conjur-ldap-sync` produces a parseable JSON report, which is printed to the `stdout`.  The process won't immediately fail if a sync step causes an error, but the corresponding item in the report will be marked as failing.  Each item in the report has an `"action"` field, describing the action, the subjects of the action, and whether the action was performed successfully.



## Running the Tests

The tests expect the following variables to be defined in the environment:

 * `CONJUR_APPLIANCE_URL`: URL of the appliance used by the features, e.g. `https://conjur.mycompany.com/api`
 * `CONJUR_AUTHN_LOGIN`: The username to use when setting up test roles.
 * `CONJUR_AUTHN_API_KEY`:  The api key or password for the user.
    * As an alternative, `CONJUR_ADMIN_PASSWORD_FILE` could be used
 * `CONJUR_ACCOUNT`: Your Conjur account.

To run the tests, run this in the project directory:

```
$ rake test
```

### Running the tests in docker image

Makefile contains several targets for this. All artifacts are stored under `./acceptance` directory

* If CONJUR\_APPLIANCE\_HOSTNAME is set, or hostname is stored under `acceptance/conjur/conjur.host`, appropriate server will be used. Otherwise, Conjur server will be launched via `conjur-ha` docker image
* If CONJUR\_ADMIN\_PASSWORD is not set, it will be autogenerated. In all cases password will be stored under `./acceptance/conjur/conjur.password`
* Test results in JUnit format will be stored in docker image called `acceptance-ldap-sync-results` and also locally in the directories `acceptance/test/{spec,cukes}_report`
* If CONJUR\_DOCKER\_REGISTRY is set up, resulting image will also be commited to this registry
* To launch Conjur server, AWS secrets must be set up, which are enlisted in `acceptance.conjurenv` file

To launch tests from docker image, run following command

```
$ conjur env run -c acceptance.conjurenv -- make acceptance/results 
```

Cleanup of Conjur server artifacts will be performed automatically.


## Contributing

1. Fork it ( http://github.com/<my-github-username>/conjur-ldap-sync/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
