#!/bin/sh

# Purpose: show all my cfengine examples using vim

for f in `ls -1`
do
  vim $f
done
