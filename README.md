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


### Basics
It maps `posixAccount` and `posixGroup` objects (as defined by RFC 2307) respectively to Conjur
users and groups, with group membership granted to appropriate users.  All created roles are granted
either to the service role or to the role specficied by the `--owner OWNER` option.

Note that if the owner role is specified, the service role must be a member of the owner role.

### Active Directory Support

The conjur-ldap-sync tool also supports Active Directory [user](https://msdn.microsoft.com/en-us/library/ms683980(v=VS.85).aspx)
and [group](https://msdn.microsoft.com/en-us/library/ms682251(v=VS.85).aspx) objects in a similar 
fashion if you provide the `--mode active_directory` flag.  This mode behaves differently from `posix`
in several ways:
    
  * Users' logins are taken from the `cn` attribute instead of the `uid` attribute.
  * Group memberships are determined by the `memberOf` attribute of user objects.
  * Object's distinguished names are determined by the `distinguishedName` attribute
    rather than the dn supplied by the server.
 
### Custom Object Classes    

The object classes selected for users and groups can be controlled by the `--group-object-classes`
and `--user-object-classes` flags, whose defaults are determined by the `--mode` flag.

### Custom LDAP Filters

If you need more flexibility than object class filters offer, you can pass an LDAP filter to use 
to select groups and/or users to be imported, using the `--user-filter` and `--group-filter` options.  
These options take precedence over the `--user-object-classes` and `--group-object-classes`.

### Source Tags

In order to prevent subsequent runs of `conjur-ldap-sync` from colliding or altering users and groups that
were created by Conjur and not from LDAP, the tool applies an [annotation](https://developer.conjur.net/reference/services/authorization/resource/annotate.html) named `ldap-sync/source`
to the Conjur assets it creates, and only manipulates objects having these annotations.

The value of this annotation is normally the id of the role as which the service is running, but you can 
set it to a different value with the `--source-tag` flag.  The `--source-tag` flag also determines which assets
will be manipulated by this run of the tool.

### Disappearance of Users and Groups

Should an LDAP user or group disappear, it will not be removed from Conjur.  Because Conjur is fully audited,
roles can never be deleted, only retired.  Retiring a role that was imported from LDAP is also problematic, 
since it would involve manipulating Conjur roles that did not originate in LDAP and might not be accessible
to the service role.  We decided to take a conservative approach, and only manipulate roles that are from LDAP.
This means that only relationships between LDAP groups and users will be destroyed if a role is deleted in LDAP. 
If you haven't manipulated the structure via Conjur, this is effectively the same as a retire that can be undone
by the service role.  Thus, if the role should reappear in LDAP, it's memberships can readily be restored.


The `conjur-ldap-sync` command accepts the following options:

    -h, --help                       Show command line help
        --version                    Show help/version info
        --log-level LEVEL            Set the logging level
                                     (debug|info|warn|error|fatal)
                                     (Default: info)
        --format FORMAT              Output format for reporting (text, json)
                                     (default: json)
        --mode MODE                  Flavor of LDAP to expect from the server (posix, active_directory)
                                     (default: posix)
        --owner OWNER                Role that will own all groups, users, and variables created
        --save-api-keys              When present, passwords will be saved to variables
        --bind-dn DN                 Bind DN for the LDAP server
        --bind-password PASS         Bind password for the LDAP server
        --no-ldap-ids                Don't import LDAP uids and gids
        --group-object-classes CLASS1,CLASS2,...
                                     LDAP objectClasses that should be imported as groups
        --user-object-classes CLASS1,CLASS2,...
                                     LDAP objectClasses that should be imported as users
        --source-tag TAG             Annotation added to assets imported from ldap.


The `--save-api-keys` is off by default, but recommended if you want to allow created roles to login to
Conjur.


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
