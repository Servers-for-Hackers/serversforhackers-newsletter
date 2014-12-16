---
title: Using Vagrant
descr: How to use Vagrant virtual machines for a better testing and development environment.
---

When working on setting up servers, as well as for development, it's useful to create a virtual server. There are several reasons why this is useful:

1. If you make a mistake, you can destroy the server and start over 
2. There's no "muck" running on your main (host) computer, but you can still code with your IDE or editor of choice.
3. You can make your virtual server as close to production as possible, leaving less surprises when installing server dependencies or code into production.
4. And the key point: You'll learn more about servers!

Let's get started with using Vagrant!

## Install Vagrant and VirtualBox

Installation is easy - download them from the respective sites and follow the installation wizards.

* Download and install [Vagrant](http://www.vagrantup.com) here
* Download and install [VirtualBox](https://www.virtualbox.org) here

## Start your First Server

I use Ubuntu LTS (long-term support) server editions. We'll use this. Head to a new folder (this is where you server will live) and use the `vagrant init` command:

```shell
# Create a new directory, head into it
mkdir ~/Sites/new-server
cd ~/Sites/new-server

# Create a new Vagrantfile
vagrant init
```

The `vagrant init` command creates a new `Vagrantfile`. This is the file which you can use to configure a new server.

Let's edit this and tell it we want to use Ubuntu 14.04, the latest LTS release. There will be lots of comments, but the meat of it (plus our addition) will be this:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "base"

end
```

We could use this as it is, but let's tell it to not use the "base" box, and to use Ubuntu 14.04 (codenamed Trusty) instead:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/trusty64"

end
```

Once that's saved, used the `vagrant up` command to download the `ubuntu/trusty64` box and start it!

## Install a Web Server

Once that's up and running, use the `vagrant ssh` command to log into your server. No need to know users or passworsd, or setup SSH keys. This will "just work".

When you're logged in, we can install some stuff! Enter this series of commands to install some basics, along with the Nginx web server:

```shell
# Update repositories of available packages
sudo apt-get update

# Install some basics
sudo apt-get install -y vim wget unzip software-properties-common

# Add a the official Nginx package repository to get 
# the latest stable version of Nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update repositories again and install Nginx
sudo apt-get update
sudo apt-get install -y nginx
```

Once that's installed, Nginx will be up and running! You can test it out:

```shell
# Make a curl request
$ curl -I localhost

# Successful output
HTTP/1.1 200 OK
Server: nginx/1.6.2
Date: Tue, 16 Dec 2014 01:19:12 GMT
Content-Type: text/html
Content-Length: 867
Last-Modified: Tue, 16 Dec 2014 01:18:55 GMT
Connection: keep-alive
ETag: "548f887f-363"
Accept-Ranges: bytes
```

Great, the web server is running! However, we can't yet access this from our web browser just yet. We need to tell our Vagrantfile that we want to be able to route requests to the server's port `80`, where Nginx is listening for web requests.

## Seeing the Web Server

Exit out the server (via the `exit` command) and edit the Vagrantfile. Make it look like this:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/trusty64"

  config.vm.network "forwarded_port", guest: 80, host: 8080

end
```

Once that's saved, run the command `vagrant reload` to make Vagrant restart the web server with our new settings. We've told that we want Vagrant to route requests to `localhost:8080` on our computer to the server's port 80, where Nginx is listening.

Once that's reloaded, enter in `localhost:8080` in your browser to see Nginx's default page!

## File Sharing

Vagrant will share your computer's directory with the `Vagrantfile` to the server's directory `/vagrant`. Use `vagrant ssh` to get back into your server, and head to the `/vagrant` directory to see that. You'll see the `Vagrantfile` there, likely the only file (other than a hidden `.vagrant` directory) there:

```shell
$ vagrant ssh
Welcome to Ubuntu 14.04 LTS (GNU/Linux 3.13.0-24-generic x86_64)
# more omiited

# Head to /vagrant directory
vagrant@vagrant-ubuntu-trusty-64:~$ cd /vagrant

# List files in the /vagrant directory
vagrant@vagrant-ubuntu-trusty-64:/vagrant$ ls -lah
total 12K
drwxr-xr-x  1 vagrant vagrant  136 Dec 16 01:21 .
drwxr-xr-x 23 root    root    4.0K Dec 16 01:21 ..
drwxr-xr-x  1 vagrant vagrant  102 Dec 16 01:13 .vagrant
-rw-r--r--  1 vagrant vagrant 4.8K Dec 16 01:21 Vagrantfile
```

## Wrapping Up

That's it! From here you can do a LOT more, but this is just about enough to get started playing in a server!

If this was too simple for you, just wait - more useful previews are on their way! You'll find lots of useful info coming your way!

## Resources

* Setting up more [forwarded ports](http://docs.vagrantup.com/v2/networking/forwarded_ports.html)
* Example of configuring [Vagrant to do a tad more](https://gist.github.com/fideloper/f838b7f44c9e2ae5b323)