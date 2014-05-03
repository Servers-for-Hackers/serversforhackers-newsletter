---
title: Permissions and User Management
topics: [Permissions, User Management]

---

<a name="permissions" id="permissions"></a>

## Permissions

Permissions in Linux can be a bit confusing. For every directory and file, there are permissions that can be set informing what users can perform operations on them, as well as what operations those users can take.

Users can perform **read (r)**, **write (w)** and **execute (x)** operations on files/directories. Here's how the three permission types breaks down when applied to directories and files:

* **Directories**
	* `read` - ability to read contents of a directory
	* `write` - ability to rename or create a new file/directory within a directory
	* `execute` - ability to `cd` into a directory
* **Files**
	* `read` - ability to read a file
	* `write` - ability to edit/write to a file
	* `execute` - ability to execute a file (such as a bash command)

The other half of this is users and groups. For any file and directory, we can define how **users (u)**, **groups (g)** and **others (o)** can interact with a directory or file. Here's how that breaks down:

* `User` - The permission for *owners* of a file or directory
* `Group` - The permissios for users belonging to a group. A user can be part of one or more groups. Groups permissions are the primary means for how multiple users can read, write or execute the same sets of files
* `Other` - The permissions for users who aren't the user or part of a group assigned to a file or directory

### Checking Permissions

Let's check the permissions of a directory, for example `/var/www`:

    $ ls -la /var/www
    drwxr-xr-x  2 root root 4096 May  3 19:52 .          # Curent Directory
	drwxr-xr-x 12 root root 4096 May  3 19:46 ..         # Containing Directory
	-rw-r--r--  1 root root   13 May  3 19:52 index.html # File in this Directory

How do these columns of information break down?

* `drwxr-xr-x` - User/Group/Other Permisions. The preceding "d" denotes this as a directory. Lacking a "d" means it's a file.
* `2` - This is the number of ["hard links"](http://superuser.com/a/443781) to the file or directory
* `root root` - The User and Group assigned to the file or directory
* `4096` - The size of the file/directory in bytes
* `4096 May  3 19:52` - last modified (or created) data/time

Most interesting to this article are the permission attributes. 

For any permission attribute set, the first slot denotes if it's a **directory (d)**, **link (l)** or **file (-)**.

Then each next set of three denotes the read, write and execute permissions for users groups and others, respectively.

Let's take the permissions `drwxr-xr-x`. 

* `d` - denotes it's a directory
* `rwx` - The user has read, write and execution permissions
* `r-x` - The group can read and execute, but not write
* `r-x` - The same for others. Since this is a directory, this means users can read the directory but not modify it or its containing files

Now let's analyze `-rw-r--r--`:

* `-` - denotes it's a file
* `rw-` - denotes users can read, write but not execute the file
* `r-x` - group members can read the file or execute it
* `r--` - others can only read the file

### Changing Permissions

We can change a file or directory permissions with the `chmod` command.

Here's some chmod information and a breakdown:

	chmod [-R] guo[+-]rwx /var/www

Flags:

* `-R` - Change permissios recursively (if its a directory)

User types:

* `u` - perform operation on the user permissions
* `g` - perform operation on the group permissions
* `o` - perform operation on the other permissions

Operations:

* `+` - add permission
* `-` - remove permission

Permission types to set

* `r` - add or remove read permissions
* `w` - add or remove write permissions
* `x` - add or remove execute permissions

So, for example, let's create the `/var/www` directory as user root and set its permissions.

	# Create directory as root
	sudo mkdir /var/www
	
	# Change to owner/group www-data:
	sudo chown www-data:www-data /var/www
	
	# Set permissions so user and group has permissions, but not other:
	sudo chmod ug+rwx /var/www # User and Group have all permissions
	sudo chmod o-rwx /var/www  # Other has no permissions
	sudo chmod o+rx /var/www   # Other can read and `cd` into the directory

This is useful if you have a user for deployment on your server. If the deployment user is part of the group `www-data`, that user will have permissions to add/update files within the `/var/www` directory.

Note that files created by a user are set to belong to that users username and main group (users belong to a main and secondary groups). This means that after creating/deploying files, we'll likely need to set their permissions properly. For example, after a deployment to `/var/www`, the deployment user should set the group and group permissions of all new files within `/var/www/` so the `www-data` group and read/write to them, and any "others" can only read them.


* [More chmod usage examples](http://fideloper.com/user-group-permissions-chmod-apache)
* [Permissions to octal (and visa-versa) calculator](http://permissions-calculator.org/)

<a name="user_management" id="user_management"></a>

## User Management

The other half of managing permissions is managing users and what groups they belong to.

Every user created by default belongs to a user and group of the same name. Users can belong to one primary group, and then can be added to other groups (plural) as their secondary groups.

The primary group is what files/directories are assigned when a user creates a new file or directory. (Their username is of course the user assigned to those same files/directories).

We can find a list of users created in the `/etc/passwd` file:

	$ vim /etc/passwd

![/etc/password](https://s3.amazonaws.com/serversforhackers/etc.passwd.png)

This will show us the following information in colon-separated columns:

* User
* Password ("x" meaning the user has an encrypted password)
* User ID (UID)
* Group ID (GID)
* User Information (extraneous notes)
* Home Directory
* Command/Shell used by the user

For more information on this list, including some notes on the UID/GID's, [see this article](http://www.cyberciti.biz/faq/understanding-etcpasswd-file-format/).

### Creating Users

Let's create a new user to use for deployments. We'll name this user "deployer".

	$ sudo adduser deployer

This will do some setup and ask you for a password for this user. This might also ask you for the user's full name and some other not-necessarily-important information.

If we check out `/etc/passwd` again, we'll see a line similar to this:

	deployer:x:1001:1003:,,,:/home/deployer:/bin/bash

In the above example, our user "deployer" has a UID of 1001 and GID (the group deployer) of 1003.

We can act as this user by running the command:

	$ sudo su - deployer

Then we can type in `groups` to see what groups we are part of:

	$ groups
	deployer

If you're following along, run the `exit` command to go back to your sudo user (`vagrant` in my case, since I'm writin this article using a Vagrant server).

Let's set our `deployer` user to have a secondary group of `www-data`. 

	$ sudo usermod -G www-data deployer

The `-G` (upper-case "G") assigns the user `deployer` the group `www-data` as a secondary group. This means that if a directory or file is part of the `www-data` group and allows group members permissions to read/write to that file, then our user `deployer` can read/modify it. Our `deployer` user can deploy to `www-data` directories!

**Alternatively**, I often make my deploy users primary group `www-data`, so that new files/directories it creates will be created with the group `www-data` automatically. Otherwise they are created with group `deployer` and we need to do the extra step of changing that and updating group permissions.

In that case, we can run:

	$ sudo usermod -g www-data deployer

The `-g` (lower-case "g") will assign the user `deployer` the group `www-data` as its primary group. This has the benefit that any files/directories created by this user will have the `www-data` group assigned to it, and we can not worry about changing the group of files/directories.

So those steps, including creating a user and assigning it the primary group `www-data`:

	$ sudo adduser deployer              # Fill in user info and password
	$ sudo usermod -g www-data deployer  # Assign group www-data (primary)

Then we can make sure our web files are in group `www-data` and ensure group members have proper permissions:

	$ sudo chgrp -R www-data /var/www
	$ sudo chmod -R g+rwx /var/www

### Basic Security

On a new server, you want to turn off the ability for user `root` to login over ssh:

	$ sudo vim /etc/ssh/sshd_config  # Edit the file controlling ssh login
	> PermitRootLogin no             #  Change from yes
	$ sudo reload ssh

If you create a new user who needs sudo privileges (but isn't the "root" user), you can assign sudo privilgesin a few ways.

In Ubuntu, you can add the user to group "sudo":

	sudo usermog -G sudo someusername

Otherwise you often need to use `visudo`:

	$ visudo    # As root user

Find a section "user privilege specification" and grant your new user all permissions:

	# User privilege specification
	root          ALL=(ALL)       ALL
	someusername  ALL=(ALL)       ALL  # Add your user here

Save and Exit there and that user will have sudo priviledges!

You may notice some fun things in there. For example, we can setup a group which allows users assigned to it have passwordless-sudo abilities. This is what Vagrant uses for its `vagrant` user:

	# Members of the admin group may gain root privileges
	%admin ALL=(ALL) NOPASSWD:ALL

Any user assigned the `admin` group will have passwordless sudo abilities.

This is how Ubuntu assigns "normal" sudo privileges to users. It defines the "sudo" group one that has sudo privilges, so we can assign sudo privileges based on groups:

	# Allow members of group sudo to execute any command
	%sudo   ALL=(ALL:ALL) ALL

Some resources:

* [Adding/Deleting users on Ubuntu and CentOS](https://www.digitalocean.com/community/articles/how-to-add-and-delete-users-on-ubuntu-12-04-and-centos-6), including giving users `sudo` abilities
* [Adding a User to a Group (or Second Group)](http://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/)
* [Docs on chgrp](http://en.wikipedia.org/wiki/Chgrp)
* [More information on Visudo and /etc/sudoers](https://wiki.archlinux.org/index.php/sudo)