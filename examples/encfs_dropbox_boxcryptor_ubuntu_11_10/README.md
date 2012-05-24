# encfs_dropbox_boxcryptor_ubuntu_11_10 - Setup encfs in ubuntu for use with boxcryptor
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Setup Encfs on a dropbox folder in ubuntu for use with boxcryptor from your android, ios,
mac, or windows device.

## REQUIREMENT
ubuntu 11.10, cfengine 3.2.1, dropbox, boxcryptor (for accessing encfs easily
from another device)

## SAMPLE USAGE
    bundle agent main {
    # Setup encfs on one of your dropbox folders for use with boxcryptor
        vars:
            "settings[user]"      string => "user";
            "settings[group]"     string => "group";
            "settings[encfs]"     string => "/home/user/Dropbox/encfs";
            "settings[mount]"     string => "/home/user/Documents/Safe";
            "settings[password]"  string => "supersecret";

        methods:
            "required_software" 
                usebundle   => install_boxcryptor,
                action      => if_elapsed("360"),
                comment     => "Install software to work with boxcryptor, but only
                                verify and try once every 6 hours";

            "encfs" 
                usebundle => encfs_init_boxcryptor("main.settings"),
                comment   => "If no encfs is found, initalize one compatible with
    boxcryptor";

            "encfs" 
                usebundle => encfs_mounted("main.settings"),
                comment => "Ensure the encfs is mounted somewhere we can write to
    it";
    }

