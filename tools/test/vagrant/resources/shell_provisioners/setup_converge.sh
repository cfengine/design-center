#!/bin/bash -x

echo kicking convergence
/var/cfengine/bin/cf-agent
echo insert meme here
/var/cfengine/bin/cf-agent
echo we do not serve memes here
/var/cfengine/bin/cf-agent
echo oh I thought you said mimes
/var/cfengine/bin/cf-agent
echo we do not serve mimes either
/var/cfengine/bin/cf-hub -q full -H `cat /var/tmp/policy_hub`
echo '* o *'
