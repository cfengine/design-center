#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check stage" => qr/R: cfdc_staging:stage/,
            "metadata check copy" => qr/R: cfdc_staging:copy/,
            "metadata check chmod" => qr/R: cfdc_staging:chmod/,
            "metadata check command" => qr/R: cfdc_staging:command/,
            "permissions" => qr[Setting permissions of /tmp/var/tmp/files_staged to owner .+, group .+, dir/file modes 755/644],
            "precommand" => qr[Options: precommand = /bin/echo precommand],
            "postcommand" => qr[Options: postcommand = /bin/echo postcommand],
            "ran precommand" => qr[Q:.+precommand],
            "ran postcommand" => qr[Q:.+postcommand],

           };

foreach (".cvs", ".svn", ".subversion", ".git", ".bzr")
{
    $todo->{"options exclude $_"} = qr/Options: excluded = $_/;
    $todo->{"exclude $_"} = qr/Excluded: $_/;
}

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
