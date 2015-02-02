---
title: Battling SELinux
topics: [Making an ally out of SELinux]
description: SELinux is powerful for security. We'll learn how to debug and get passed common issues run into with SELinux.
---

We all run into SELinux at one point. When something doesn't work, and you just can't figure out why:

![Seinfield reference. You better get it.](https://s3.amazonaws.com/serversforhackers/58518168.jpg)

The following video will cover some common scenarios in using SELinux with Apache, as well as how to most easily debug them.

This isn't in-depth, but it will get you in a good-enough place so you don't simply turn off SELinux to make something work!

Here's the video **Battling SELinux** (apologies if the font-size in the terminal is a little on the small side!):

<iframe src="//player.vimeo.com/video/117875375" width="100%" height="517" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

## The Rundown:

Here's a rundown of the various commands done in this video. Note that this video was recorded using RedHat Enterprise 7 - the official RedHat AMI provided within Amazon EC2.

### Three ways to Show current SELinux status:

```shell
# 1. Check overall status
sudo sestatus

# 2. Check if SELinux is enforcing
sudo getenforce
```

Note that SELinux can be enabled, but not enforcing. This is good for auditing potential issues, since SELinux will log things that would normally get blocked (but it will not block them).

Alternatively (3), check in `/etc/selinux/config` for `SELINUX=disabled`:

```shell
sudo vim /etc/selinux/config
```

### Check file and directory SELinux labels/context

```shell
# Check current directory
ls -Z
# ... or to see hidden (dot) files in the current directory as well
ls -lahZ

# We can search running processes for SELinux labels
# The following searches for "httpd" processes
sudo ps aux -Z | grep httpd

# We can check network interfaces for SELinux labels
# The following checks networks for mysql
sudo netstat -a -Z | grep mysql
```

### Server Setup to Follow Along

```shell
# Install vim, tmux, apache, php and mariadb
sudo yum install vim tmux httpd mariadb-server php php-mysql php-mcrypt php-curl
# Ensure Apache and MariaDB start on system boot
sudo systemctl enable httpd.service
sudo systemctl enable mariadb.service

# Start Apache and MariaDB
sudo service httpd start
sudo service mariadb start

# Set root password for MariaDB and
# clean up test data & permissions
sudo mysql_secure_installation
```

Next we'll make MariaDB listen on localhost port 127.0.0.1, which will help us illustrate SELinux blocking network connections between Apache and the database, listening on the localhost network (loopback interface).

In `/etc/my.cnf.d/server.cnf`

```
[mysqld]
bind-address = 127.0.0.1
```

Then restart MariaDB:

```
sudo service mariadb restart
```

### SELinux Helper Libraries for Debugging

Note: these took an above-average amount of time to install:

```shell
# Install the SELinux troubleshooting tools
sudo yum install setroubleshoot setroubleshoot-server

# Restart auditd services so changes take affect
sudo service auditd restart
```

### PHP Script Used to Test Issues

In the video, the following was located at `/var/www/html/index.php`:

```php
<?php
// Test network connection
try {
    $dbh = new PDO('mysql:host=127.0.0.1;dbname=my_db', 'root', 'root');
} catch( \Exeception $e )
{
    echo  $e->getMessage();
}

// Test writing files
file_put_contents('./uploads/text.txt', 'this is some text');
```

### Connect over network to database

Try PHP script, get errors. 

Check `/var/log/audit/audit.log`.

Check `/var/log/messages`. **The log will contain the most user-friendly messages, including suggestions and commands to run**. It will only have that messaging after install the `setroubleshoot` tools.

To fix the issue of Apache not being able to "talk" to MariaDB:

```shell
# -P is permanent
sudo setsebool -P httpd_can_network_connect_db 1
```

TO view available booleans related to Apache:

```shell
sudo getsebool -a | grep httpd
```

You can use a similar command for issues you run into and check if there are booleans related to the software you may be having issues with.

### Write to File System

Create a data directory and ensure Apache can write to it (regular Linux permissions):

```shell
sudo mkdir -p /var/www/html/data
sudo chmod o+rwx /var/www/html/data
```

See that the PHP script still cannot write to the `data` directory. Check the `/var/log/messages` log:

```shell
sudo tail -n 50 -f /var/log/messages
```

See that it wants us to create a new context for the `/var/www/html/data` directory via `semanage fcontext` command. Instead, we'll keep it simple by just adjusting the "type" label of the `data` directory:

```shell
sudo chcon -Rv --type=httpd_sys_content_rw_t /var/www/html/data
```

If you want to check file contexts set by SELinux, related to Apache, run the following. Note that this file is read-only:

```shell
cat /etc/selinux/targeted/contexts/files/file_contexts | grep httpd
```

## Resources

* An [amazing talk on using SELinux](https://www.youtube.com/watch?v=MxjenQ31b70)
* The [slides for said talk](http://people.redhat.com/tcameron/Summit2012/SELinux/cameron_w_120_selinux_for_mere_mortals.pdf)
* Seriously, watch that talk.
* [Building a SELinux policy module](http://www.relativkreativ.at/articles/how-to-compile-a-selinux-policy-package)

