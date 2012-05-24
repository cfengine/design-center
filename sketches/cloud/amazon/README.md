# Managed Amazon cloud image

##AUTHOR
Eystein Måløy Stenberg <eystein@cfengine.com>

##PLATFORM
Linux

##DESCRIPTION
Launch images in the Amazon Elastic Compute Cloud and install CFEngine
during boot with a user-data script.

Canonical provides [Ubuntu AMIs](http://cloud.ubuntu.com/ami/) that
support the user-data script hook. For example, ami-0baf7662 is a 64-bit
Ubuntu 10.4 AMI located on the us-east-1 zone. Other operating system AMIs
supporting the user-data script hoook are widely available.

It is recommended that you host the CFEngine package to install on the Amazon
Simple Storage Service both since the data-transfer is free from EC2 and 
for performance reasons.

The user-data script to run is provided as `install-cfengine-client`
as part of this sketch. For performance reasons, it is recommended
that you create all your clients in the same availablility zone as the
policy server. When the hub is set up and `install-cfengine-client`
reflects your configuration, you can run the following command
(substituting uppercase options with the desired configuration).

"ec2-run-instances ami-AMI-ID --key KEYPAIR-NAME --user-data-file install-cfengine-client --instance-type INSTANCE-TYPE --instance-count INSTANCE-COUNT --group sg-SGROUPID -availability-zone ZONE-OF-POLICY-SERVER"

##REQUIREMENTS
 * An Amazon Elastic Compute Cloud account
 * A CFEngine policy server already set up and accepting connections from the new clients (see def.acl)
 * A CFEngine client package to install, preferably hosted on Amazon Simple Storage Service
 * An AMI ID to launch, which supports the user-data script hook
 * [ec2 api tools](http://aws.amazon.com/developertools/351) installed an configured on your workstation
 * A security group accepting inbound connections on port 5308

##SAMPLE USAGE
 * Manually set up the CFEngine policy server, preferably on the Elastic Compute Cloud
 * Edit the variables in `install-cfengine-client` to reflect your configuration
 * Run "ec2-run-instances ami-0baf7662 --key mykey --user-data-file install-cfengine-client --instance-type t1.micro --instance-count 5 --group sg-2d194113 -availability-zone us-east-1d"

##TODO
 * Create a user-data script to set up the policy server
 * Provide a shared Amazon Simple Storage Service bucket with CFEngine packages
 * Create a mechanism in the user-data script to set a class on the new CFEngine instance
 * Make a script that generates the user-data script based on the variables
 * Use VPC to shield clients from internet access (--subnet option), but [Amazon does not support micro instances in VPC](https://forums.aws.amazon.com/thread.jspa?threadID=51373)