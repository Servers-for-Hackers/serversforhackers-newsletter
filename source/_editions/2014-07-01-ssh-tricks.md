---
title: SSH Tricks
topics: [Logging In]
description: Description for SSH tricks
draft: true
---
# SSH Tricks

We use SSH to log into our servers, but it actually has a lot of neat tricks it can help us with as well! We'll cover some of them here.

## Logging in

Of course, we use SSH to login:

	$ ssh user@hostname

And, if needed, we can specify a different port:

	$ ssh -p 2222 user@hostname	

Sometimes, if we have a lot of SSH keys in our `~/.ssh` directory, we'll often find that SSHing into servers with the intent of using a password results in a "too many authentication attempts" error. If we need to log into a server with a password, we can attempt to force password-based login. This will stop SSH from attempting to use your SSH keys first:

	$ ssh -o "PubkeyAuthentication no" username@hostname

If you use AWS, and in other cases, you might get a PEM file to use as an identity. In this case, you might need to specify a specific identity file to use when logging in. We can do this with the `-i` flag:

	$ ssh -i /path/to/identity.pem username@hostname

> You may need to set your permissions on the pem file so only the owner can read/write/execute it: `chmod 0600 identity.pem` or `chmod u+rw identity.pem && chmod go-rwx identity.pem`

### SSH Config

Here's something really powerful. 

If you want to setup aliases for servers you access often, you can create an `~/.ssh/config` file and specify each server you log into, along with the authentication method to use:

	$ vim ~/.ssh/config
	
	Host somealias
		HostName example.com
		Port 2222
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
* **Port** - The port to use when connecting
* **User** - The username to log in with
* **IdentityFile** - The SSH key identity to use to log in with, if using SSH key access
* **IdentitiesOnly**  - "Yes" to specify only attempting to log in via SSH key
* **PubkeyAuthentication** - "No" to specify you wish to bypass attempting SSH key authentication

## Tunneling

SSH can be used for tunneling, which is essentially port forwarding. There's a few ways we can do this - Local (Outbound), Remote (Inboud), and some others (Dynamic and Agent Forwarding).

### Local Port Forwarding

Local port forwarding is what you use when you need to tunnel through a server's firewall or other limitation. 

A common example is attempting to connect to a remote database which is either behind a firewall or is only listening to local connection. For example, MySQL only listens to localhost connections by default. You can't remotely connect to it without editing the `my.cnf` file and have it listen on all networks. There's also a firewall preventing you connecting to MySQL's port 3306 anyway.

> Remote means any computer that isn't yours, which includes virtual machines (guests) inside of your host computer

Assuming we have SSH access to the remote server, we can get around this by creating a tunnel into the server. What might that look like?

	ssh -L 3306:localhost:3306 username@hostname

Let's go over this:

* `-L` - Setup local port forwarding
* `3306` - The local port to forward
* `localhost:3306` - Within the remote server, what address and port to forward traffic to. Since the MySQL server is on the remote server, we're tunneling to the remote server's "localhost" on port 3306, which MySQL is listening to.
* `username@localhost` - The SSH username and host to connect to

I can then use my local client to connect to the remote server as if it's a local one:

![](https://s3.amazonaws.com/serversforhackers/tunnela.png)

Now, I used the same port locally and remotely, but I could have specified a different local port to use:

	ssh -L 3307:localhost:3306 username@hostname

Then my local mysql client would have to connect to port `3307`, which would still tunnel to the remote server's local `3306`:

![](https://s3.amazonaws.com/serversforhackers/tunnelb.png)

<!-- should talk about "localhost" and "127.0.0.1" being lo, "*" being used to all interfaces, and specific IP addresses for eth* interface binding -->

### Remote Port Forwarding

Remote Port Forwarding is good if you need to share your local computer with others who are outside of your network.

To do this, we need a remote server all parties can reach. Something like a AWS or Digital Ocean server will do.

First, let's pretend our local computer has a web server running on port `8001`:

	# On our local machine:
	$ curl localhost:8001
	Hi!

We want our friends to see our website, which simply says "Hi!". Let's use a remote server to forward requests to our local computer:

	# Still on our local machine:
	ssh -R 9000:localhost:8001 username@hostname

Let's go over this command:

* `-R` - Using remote port forwarding
* `9000` - The remote server's port to use (not our local server this time!)
* `localhost:8001` - The local address to forward to. Since our webserver is on localhost port `8001`, that's what we specify here. (Yep, the order of those arguments changed for -R over -L!)
* `username@hostname` - SSH access to the remote server

If our remote server's IP address was `123.123.123.123`, then our friends can access our website at `123.123.123.123:9000`, which will forward to our local site at `localhost:80001`!

**Note:** To accomplish this, your remote server's firewall much not block port `9000`. You may also need to edit `/etc/ssh/sshd_config` and set the `GatewayPorts` directive to `yes`. (Don't forget to restart SSH after any changes to `sshd_config`).




## Cover

* SSH in
* [One-off commands with SSH](http://www.symkat.com/ssh-tips-and-tricks-you-need)
* [SSH force password](http://bijayrungta.com/force-ssh-to-use-password-instead-of-public-key)
* SSH in with pem file (AWS) - `-i` flag
* Use `~/.ssh/config` file
* [SSH Tunnel](http://blog.sensible.io/2014/05/17/ssh-tunnel-local-and-remote-port-forwarding-explained-with-examples.html) (use mysql without binding it to allow remote connections)
* One-off commands (And Ansible?)
* Packages:
	* Shunt (php)
	* Envoy (php)
	* Ansible (quick example)
	

## Resources:

* http://blog.tjll.net/ssh-kung-fu
* http://www.symkat.com/ssh-tips-and-tricks-you-need (incl. one off command)