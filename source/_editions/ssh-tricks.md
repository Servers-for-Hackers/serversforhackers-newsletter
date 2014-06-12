# SSH Tricks

We use SSH to log into our servers, but it actually has a lot of neat tricks it can help us with as well! We'll cover some of them here.

## Logging in

Of course, we use SSH to login:

	$ ssh user@hostname

And we can use a different port:

	$ ssh -p 2222 user@hostname	

Sometimes, if we have a lot of SSH keys in our `~/.ssh` directory, we'll often find that SSHing into servers with the intent of using a password results in a "too many authentication attempts" error. If we need to log into a server with a password, we can attempt to force password-based login. This will stop SSH from attempting to use all your SSH keys first:

	$ ssh -o "PubkeyAuthentication no" username@hostname

If you use AWS, and in other cases, you might get a PEM file to use as an identity. In this case, you might need to specify a specific identity file to use when logging in. We can do this with the `-i` flag:

	$ ssh -i /path/to/identity.pem username@hostname
	
> You may need to set your permissions on the pem file so only the owner can read/write/execute it: `chmod 0777 identity.pem` or `chmod u+rwx identity.pem && chmod go-rwx identity.pem`

Finally, if you want to setup aliases for servers you access often, you can create an `~/.ssh/config` file and specify each server you log into, along with the authentication method to use:

	$ vim ~/.ssh/config
	
	Host somealias
		HostName example.com
		User someuser
		IdentityFile  ~/.ssh/id_example
		IdentitiesOnly yes
		
	Host anotheralias
		HostName 192.168.33.10
		User anotheruser
		PubkeyAuthentication no
	
	How aws
		HostName some.address.ec2.aws.com
		User awsuser
		IdentityFile  ~/.ssh/aws_identity.pem
		IdentitiesOnly yes

So, there's a few example entries you might find in the `~/.ssh/config` file (you can have as many entries as you'd like).

Using a defined host ("alias") is as easy as this:

	$ ssh somealias

Let's cover the options used above:

* **HostName** - The server host (domain or ipaddress)
* **User** - The username to log in with
* **IdentityFile** - The SSH key identity to use to log in with, if using SSH key access
* **IdentitiesOnly**  - "Yes" to specify only attempting to log in via SSH key
* **PubkeyAuthentication** - "No" to specify you wish to bypass attempting SSH key authentication

## Tunneling



## Cover

* SSH in
* [One-off commands with SSH](http://www.symkat.com/ssh-tips-and-tricks-you-need)
* [SSH force password](http://bijayrungta.com/force-ssh-to-use-password-instead-of-public-key)
* SSH in with pem file (AWS) - `-i` flag
* Use `~/.ssh/config` file
* [SSH Tunnel](http://blog.sensible.io/2014/05/17/ssh-tunnel-local-and-remote-port-forwarding-explained-with-examples.html) (use mysql without binding it to allow remote connections)
* Packages:
	* Shunt (php)
	* Envoy (php)
	* Ansible (quick example)
	

## Resources:

* http://blog.tjll.net/ssh-kung-fu
* http://www.symkat.com/ssh-tips-and-tricks-you-need (incl. one off command)