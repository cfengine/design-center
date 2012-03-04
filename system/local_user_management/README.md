# local_user_management - Bundles to help you manage local user accounts
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* local_user_management_add_users_fileedit takes care of initalizing new users then it
  leaves them alone. Tries to stick with edit_line based functionality instead
  of calling out to system tools.

## REQUIREMENTS
* local_user_management_add_users_fileedit
    - perl
    - copbl svn 105 or greater


## SAMPLE USAGE
### local_user_management_add_users_fileedit
User Definition API
"users[username][option] string => "value";
Options
* gecos - required
* uid - required
* home - required
* shell - required
* passwdhash - optional
* groupname - optional, named group creation if does not exist, will not allow
  duplicate gids without _allow_dup_gid option.
* _allow_dup_gid - optional, enable creation of named group with non-unique gid
* _enforce - optional, completely enforce users passwd and shadow entries 
* _nocreate_home - optional, do not create home directory
* _noseed - optional, do not seed home directory

Note on password hashes:
this perl oneliner should generate valid hashed passwords, replace MYPASSWORD
with your password. Be sure your system supports whatever encryption method
you choose. Thanks Scott Hunter <scott.hunter.iii@gmail.com> for the oneliners.


* For sha512 
```
    perl -e '@letters = ("A".."Z", "a".."z", "0".."9", "/", "."); $salt = join("", map { $letters[rand@letters]; } (0..85)); print crypt("MYPASSWORD", q[$6$] . $salt) . "\n";'
```
* For sha256 
```
    perl -e '@letters = ("A".."Z", "a".."z", "0".."9", "/", "."); $salt = join("", map { $letters[rand@letters]; } (0..42)); print crypt("MYPASSWORD", q[$5$] . $salt) . "\n";'
```
* For md5
```
    perl -e '@letters = ("A".."Z", "a".."z", "0".."9", "/", "."); $salt = join("", map { $letters[rand@letters]; } (0..21)); print crypt("MYPASSWORD", q[$1$] . $salt) . "\n";'
```

``` 
body common control {

    bundlesequence  => {
                        "main",
                        };

    inputs          => {
                        "cfengine_stdlib.cf",
                        "sketches/local_user_management/local_user_management.cf",
                        };
}

bundle agent main {

    vars:
        # This is a typical user creation definition
        # Note the group id that is assigned to the user may 
        # or may not be named
        ## This test should not create a named group ##
        "users[testuser1][gecos]"          string => "Test User1";
        "users[testuser1][uid]"            string => "1501";
        "users[testuser1][gid]"            string => "1501";
        "users[testuser1][home]"           string => "/home/testuser1";
        "users[testuser1][shell]"          string => "/bin/bash";
        "users[testuser1][passwdhash]"     string => "$1$cCMJbSmS$/tQtxSsLZmYq3/zp1Vm/l0";
        "users[testuser1[_nocreate_home]"  string => "nohome";


        # This user definition includes a named group
        # If there is not currently a named group with the specified
        # gid the new named group will be created. If there is already
        # a named group with the specificed gid the new named group
        # will not be created because of the conflicting gid. The named
        # group gid conflict will not prevent the user from being created
        ## This test should not create a named group ##
        "users[testuser2][gecos]"          string => "Test User2";
        "users[testuser2][uid]"            string => "1502";
        "users[testuser2][gid]"            string => "100";    # to test pick a gid here thats already in use on your system
        "users[testuser2][home]"           string => "/home/testuser2";
        "users[testuser2][shell]"          string => "/bin/bash";
        "users[testuser2][passwdhash]"     string => "$1$cCMJbSmS$/tQtxSsLZmYq3/zp1Vm/l0";
        "users[testuser2][groupname]"      string => "testgroup2";
        "users[testuser2[_noseed]"         string => "For whatever reason, we dont want to seed this users homedir";


        # This user definition includes a named group as well as 
        # an override to allow the specified named group to have
        # a non-unique gid. In addition to creating the user
        # The named group will be created if it does not already exist.
        ## This test should create a named group ##
        "users[testuser3][gecos]"          string => "Test User3";
        "users[testuser3][uid]"            string => "1503";
        "users[testuser3][gid]"            string => "100";     # to test pick a gid here thats already in use onyour system
        "users[testuser3][home]"           string => "/home/testuser3";
        "users[testuser3][shell]"          string => "/bin/bash";
        "users[testuser3][passwdhash]"     string => "$1$cCMJbSmS$/tQtxSsLZmYq3/zp1Vm/l0";
        "users[testuser3][groupname]"      string => "testgroup3";
        "users[testuser3][_allow_dup_gid]" string => "its ok to have a duplicate gid here";
        "users[testuser3[_enforce]"        string => "";



    methods:
        "any" usebundle => local_user_management_add_users_fileedit("main.users");

    reports:
    cfengine::
    "Verify and Cleanup";
    "grep testuser /etc/passwd";
    "grep testgroup /etc/group";
    "sudo userdel testuser1;sudo rm -rf /home/testuser1";
    "sudo userdel testuser2;sudo rm -rf /home/testuser2";
    "sudo userdel testuser3;sudo rm -rf /home/testuser3";

}
```
