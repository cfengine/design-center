# local_user_management - Bundles to help you manage local user accounts
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* local_user_management_add_users takes care of initalizing new users then it
  leaves them alone. Tries to stick with edit_line based functionality instead
  of calling out to system tools.

## REQUIREMENTS
* local_user_management_add_users
    - perl
    - copbl svn 105 or greater


## SAMPLE USAGE
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
    vars:
        "users[testuser][gecos]"          string => "My Test User";
        "users[testuser][uid]"            string => "1500";
        "users[testuser][gid]"            string => "1500";
        "users[testuser][home]"           string => "/home/testuser";
        "users[testuser][shell]"          string => "/bin/bash";
        "users[testuser][passwdhash]"     string => "$1$cCMJbSmS$/tQtxSsLZmYq3/zp1Vm/l0";

    methods:
        "any" usebundle => local_user_management_add_users("scope.users");
```
