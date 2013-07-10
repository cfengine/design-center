N:=2
OP=up
VM:=
# notable REST options: bootstrap and dc
REST:=

ubuntu10-none:
	vagrant $(OP) $(VM) -- -inone --vmname=ubuntu-10.04- --box=ubuntu-10.04 --count=$(N) $(REST)

ubuntu13-none:
	vagrant $(OP) $(VM) -- -inone --vmname=ubuntu-13.04- --box=ubuntu-13.04 --count=$(N) $(REST)

ubuntu10-core:
	vagrant $(OP) $(VM) -- -icore --vmname=ubuntu-10.04- --box=ubuntu-10.04 --count=$(N) $(REST)

ubuntu13-core:
	vagrant $(OP) $(VM) -- -icore --vmname=ubuntu-13.04- --box=ubuntu-13.04 --count=$(N) $(REST)

ubuntu10-packages:
	vagrant $(OP) $(VM) -- -ipackages --vmname=ubuntu-10.04- --box=ubuntu-10.04 --count=$(N) $(REST)

ubuntu13-packages:
	vagrant $(OP) $(VM) -- -ipackages --vmname=ubuntu-13.04- --box=ubuntu-13.04 --count=$(N) $(REST)

centos64-packages:
	vagrant $(OP) $(VM) -- -ipackages --vmname=centos-6.4- --box=centos-6.4 --count=$(N) $(REST)
