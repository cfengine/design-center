#!/bin/sh

# install pre-req's for cf-sketch on RHEL 6

yum install perl-CPAN perl-YAML perl-Term-ReadLine-Gnu
yes yes | perl -MCPAN -e 'install JSON::PP'
