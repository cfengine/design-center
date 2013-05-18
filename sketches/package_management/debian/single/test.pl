#!/usr/bin/perl

use warnings;
use strict;

use lib "../../../libraries/dclib";
use dctest;

my $todo = {
    #"metadata check" => qr/R: cfdc_etc_hosts:configure: System::etc_hosts/,
    "install package 1" => qr/R: ___001_Packages_Debian_single_install: would install package install_package_1, version version_1, release release_1\n/,
    "install package 2" => qr/R: ___002_Packages_Debian_single_install: would install package install_package_2, version version_2\n/,
    "install package 3" => qr/R: ___003_Packages_Debian_single_install: would install package install_package_3, release release_3\n/,
    "install package 4" => qr/R: ___004_Packages_Debian_single_install: would install package install_package_4\n/,
    "verify package 1" => qr/R: ___005_Packages_Debian_single_verify: would verify package verify_package_1, version version_1\n/,
    "verify package 2" => qr/R: ___006_Packages_Debian_single_verify: would verify package verify_package_2\n/,
    "remove package 1" => qr/R: ___007_Packages_Debian_single_remove: would remove package remove_package_1\n/,

    "install return 001" => qr/R: activation ___001_Packages_Debian_single_install returned package_installed = 1/,
    "install return 002" => qr/R: activation ___002_Packages_Debian_single_install returned package_installed = 1/,
    "install return 003" => qr/R: activation ___003_Packages_Debian_single_install returned package_installed = 1/,
    "install return 004" => qr/R: activation ___004_Packages_Debian_single_install returned package_installed = 1/,
    "verify return 005" => qr/R: activation ___005_Packages_Debian_single_verify returned package_verified = 1/,
    "verify return 006" => qr/R: activation ___006_Packages_Debian_single_verify returned package_verified = 1/,
    "remove return 007" => qr/R: activation ___007_Packages_Debian_single_remove returned package_removed = 1/,
};

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
