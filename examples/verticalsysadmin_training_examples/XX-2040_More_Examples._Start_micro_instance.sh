#!/bin/sh

MY_HOST_ALIAS=$1

#INSTANCE_ID=`ec2-run-instances -t t1.micro  ami-6c06f305 -k mysshkey 2>&1 | awk '/^INSTANCE/ {print $2}'`  #ubuntu image
INSTANCE_ID=`ec2-run-instances -t t1.micro  ami-7c827015 -k mysshkey 2>&1 | awk '/^INSTANCE/ {print $2}'`   #centos image

INSTANCE_HOSTNAME=pending

while [ "${INSTANCE_HOSTNAME}" = "pending" ]
do
	sleep 4
        INSTANCE_HOSTNAME=`ec2-describe-instances $INSTANCE_ID | awk '/^INSTANCE/ {print $4}'`


done

INSTANCE_ADDRESS=`ec2-describe-instances $INSTANCE_ID | awk '/^INSTANCE/ {print $14}'`
echo $INSTANCE_ADDRESS $MY_HOST_ALIAS $INSTANCE_ID | tee -a hosts.ec2

sudo sh -c "echo $INSTANCE_ADDRESS   $MY_HOST_ALIAS  >> /etc/hosts"

sleep 70  # wait for EC2 to provision the instance

/usr/bin/ssh -t -o StrictHostKeyChecking=no -i /home/user/ec2/mysshkey_key.pem ec2-user@${INSTANCE_HOSTNAME} sudo sh -c "\"hostname $MY_HOST_ALIAS\""


#nohup
sh -c "sleep 70 \
&& \
/usr/bin/scp \
 	-o StrictHostKeyChecking=no \
 	-i /home/user/ec2/mysshkey_key.pem\
 	/home/user/Downloads/cfengine-community-3.1.4-1.centos5.x86_64.rpm \
        /home/user/cfengine_ec2/example102_wordpress_installation.cf \
 	ec2-user@${INSTANCE_HOSTNAME}: \
 	&& \
 	/usr/bin/ssh \
                -t \
   		-o StrictHostKeyChecking=no \
   		-i /home/user/ec2/mysshkey_key.pem \
   		ec2-user@${INSTANCE_HOSTNAME} \
     		'/usr/bin/sudo rpm -i cfengine-community-3.1.4-1.centos5.x86_64.rpm && \
                 rm cfengine-community-3.1.4-1.centos5.x86_64.rpm &&
                 /usr/bin/sudo rsync -qa /usr/local/share/doc/cfengine/inputs/ /var/cfengine/inputs/ && \
                 /usr/bin/sudo /usr/local/sbin/cf-agent;  '" 
#>/dev/null 2>/dev/null &
