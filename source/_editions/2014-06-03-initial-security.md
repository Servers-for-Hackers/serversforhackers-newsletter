---
title: Some Light Security
topics: [SSH Access, Firewalls]

---

When we first get our hands on a fresh server, some initial security precautions are always warranted, especially if the server is open to a public network. The servers we get on a lot of our popular providers (Digital Ocean, Linode, Rackspace, AWS and so on) are usually open to the public - they are assigned an IP address on their public network upon creation.

We'll cover some initial, important security precautions to take.

<a name="ssh_access" id="ssh_access"></a>

## SSH Access

Many hosting/server providers start you off with password-based access to the root user (or occasionally a sudo user who doesn't need a password to run commands as root, similar to Vagrant). The root user can do *anything* to our system, and so we want to lock down the ability for remote connections to log in as root.

So, if we want to remove the ability to remotely access our server as user "root", we need another user to connect with. This user also needs the ability run privileged commands.

We'll do the following to lock down remote access to our server:

1. Create a new user
2. Allow this user to use "sudo"
3. Stop root user from remotely logging in

That will stop user "root" from remotely logging in and allow our new user to log in. This new user will need a password to run any privileged commands.

Then we'll take this one step further - we'll stop users from being able to login with a password altogether, using SSH keys instead. We'll do the following:

1. Create an SSH key on our local computer
2. Turn off password-based authentication on our server

### Initial User Setup

Alright, let's get started. First, you'll need to log into the server with the credentials your provider gave you. For most, that's something like this:

	$ ssh root@your-server-ip

AWS might require you to use a downloaded identity file (Ubuntu users might be given user "ubuntu" instead of "root"):

	$ ssh -i /path/to/identity.pem root@your-server-ip

> For the majority of this article, I'm assuming you're logged in as root, and thus don't need to use "sudo" to run the following commands.

Once you're in, you an create a new user:

	$ adduser someusername

This will ask you for some information, the most important of which is the password. Take the time to add a [somewhat lengthy, secure password](https://identitysafe.norton.com/password-generator).

CentOS might require you to run `passwd someusername` to set a password on the new user.

> Don't [confused the `adduser` command with the `useradd` command](http://askubuntu.com/questions/345974/what-is-the-difference-between-adduser-and-useradd). Using `adduser` takes care of some work that we'd have to do manually otherwise. You can leave the other questions empty or add in their information (full name, room number, and other somewhat useless information).

Next, we need to make this new user (`someusername`) a sudo user. This means allowing the user to use "sudo", to run commands as root. How you do this changes per operating system. On Ubuntu, you can simply add the user to the "sudo" group. (If you need a refresher on what groups are, see the past edition [Permissions and User Management](http://serversforhackers.com/editions/2014/05/06/permissions-users/)).

	$ usermod -G sudo someusername

Let's go over that command quickly:

* `-G sudo` - Assign the group "sudo" as a secondary group
* `someusername` - The user to assign the group to

That's it! Now, on non-Ubuntu systems (RedHat, CentOS), you may need to do some extra work to do the same.

The [process is written up nicely here](https://www.digitalocean.com/community/articles/initial-server-setup-with-centos-6), but is essentially just running the command `visudo` and appending the following to the "# User privilege specification" section (Fair warning - It uses Vim as an editor!):

	someusername    ALL=(ALL)       ALL

Now that we have a new, privileged user, we want to stop user "root" from remotely logging in.

To do this, we need to edit the `/etc/ssh/sshd_config` file.

	# Edit with vim
	$ vim /etc/ssh/sshd_config
	
	# Or, if you're not a vim user:
	$ nano /etc/ssh/sshd_config

Once inside that file, find the `PermitRootLogin` option, and set it to "no":
 
	PermitRootLogin no

You may also want to change the default SSH port (22) used. This is because a lot of automated systems scan port 22 to see if its an open for attack. You're allowed to use ports between 1025 and 65536. To do so, you can simply change the `Port` option:

	Port 1234 # But don't use "1234"

If you want to get even more secure, you can explicitly define a list of users who are allowed to login. That's with the `AllowUsers` option:

	AllowUsers someusername someotherusername

Once you save and edit from the `/etc/ssh/sshd_config` file, we need to reload the SSH daemon.

	# On Debian/Ubuntu
	$ service sshd reload
	
	# RedHat/CentOS
	$ /etc/init.d/sshd reload

That's it! Before you close your session as user root, I sugget you now open a **new** terminal window (session) and attempt to log in with your new user:

	# If you left the default port:
	$ ssh someusername@your-server-ip
	
	# If you changed the SSH port number:
	$ ssh -p 1234 someusername@your-server-ip

You should beA prompted for a password - enter the one you created and you should be logged in! Try running some commands as "sudo" to ensure it works. 

### SSH Key Access

Assuming that's working, we can take this a step further by disallowing users to log in with a password. This means users can only log in with a valid SSH key. This is more secure as it's substantially less likely for a user to get their hands on your SSH private key than it is for them to obtain or guess a password.

On your local computer, the one from which you log into your server (for me, that's my Macbook), run the following command to generate a new SSH key pair (a private and public key):

	$ cd ~/.ssh
	$ ssh-keygen -t rsa -b 4096 -C your@email.com -f id_myserveridentity

Let's cover this command:

* `-t rsa` - Create and [RSA type key](http://security.stackexchange.com/questions/23383/ssh-key-type-rsa-dsa-ecdsa-are-there-easy-answers-for-which-to-choose-when).
* `-b 4096` - Use 4096 bits. 2048 is "usually sufficient", but I go higher.
* `-C your@email.com` - Keys can have comments. Often a user's identity goes here, such as their email address
* `-f id_myserveridentity` - The name of the files created (id_myserveridentity and id_myserveridentity.pub in this case)

This will ask your for a password. You can either leave this blank (for passwordless access) or enter in a password. I **highly** suggest using a password - making it so attackers require both your private key AND your SSH password to gain SSH access, in addition to your user's password to run any sudo command on the server! That's three hard things an attacker would need to get in order to do real damage to your server.

> Note that the SSH password you create is NOT the user password used to run sudo commands on the server.

Now we've created a private key file (id_myserveridentity) and a public key file (id_myserveridentity.pub). We need to put the public key on the server, so that the server knows its a key authorized to be used to log in. Copy the contents of the public key file (on mac: `cat ~/.ssh/id_myserveridentity.pub | pbcopy` will add it to your clipboard).

Once that's copied, you can go into your server as your new user ("someusername" in our example).

	# In your server
	$ sudo nano ~/.ssh/authorized_key
	> Paste in your public key and save/exit

So, we're simply appending the public key from our local computer to the `authorized_keys` file of the newly created user on our server. If there's already a key in the `authorized_key` file, just add yours on a newline underneath the other.

Then you should be able to login with

## Resouces

* [Initial server setup on CentOS](https://www.digitalocean.com/community/articles/initial-server-setup-with-centos-6)
* Various ways to [only allow specific users SSH access](http://knowledgelayer.softlayer.com/learning/how-do-i-permit-specific-users-ssh-access)
* [A Comprehensive SSH Key Primer](http://epocsquadron.com/a-comprehensive-ssh-key-primer/)