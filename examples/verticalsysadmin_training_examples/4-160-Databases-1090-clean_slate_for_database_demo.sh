#!/bin/sh

yum -y remove postgresql postgresql-server
rm -rf /var/lib/pgsql
