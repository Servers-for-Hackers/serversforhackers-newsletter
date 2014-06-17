---
title: Vagrant and Apache
topics: [Getting Off of MAMP, Configuring Apache Virtual Hosts]
description: This is the very first Servers for Hackers newsletter. We'll get off of MAMP, and into Vagrant and setting up Apache!
---

This is the very first Servers for Hackers newsletter. As one of the main goals of this newsletter is to get those less experienced on the server side of things get their feet wet, we'll start with some basics.

First, we'll discuss getting off of MAMP (or WAMP/XAMP for that matter) and start using a Virtual Machine. Then we'll talk about configuring Apache virtual hosts, as it's commonly a next step after installing Apache.

---

<a name="getting-off-mamp" id="getting-off-mamp"></a>

# Getting Off of MAMP

There's a large number of PHP users who rely on their trusty *AMP installs to "just work". However, many need to go beyond default setups for certain frameworks or projects. When you do, these "easy" tools break down because the operating systems (and/or the [applications](http://stackoverflow.com/search?q=mamp+phpunit)) on which you work [break standards](http://stackoverflow.com/search?q=mamp+artisan) set by the Linux/Unix servers on which the projects likely will live in production.

When you start hitting these walls, it's time to leave *AMP behind and start using virtual machines to set up a "real" server. You'll never look back.

## Vagrant: Level 1

Begin with installing and creating a quick server.

[Vagrant](http://www.vagrantup.com) makes this an especially pleasant process. I suggest taking it slow. Many tutorials will go on and on about using provisioning systems like Puppet, Chef or Ansible. If you're new to this, ignore all of that.

> **Vocabulary**: Your computer is called the "**host**" machine. Any virtual machine created within the host machine is called a "**guest**" machine.

The first thing to do is, of course, install [Vagrant](http://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org) (there's no trick, just download and install!). After you install these, you can open your terminal and run a few commands to get started. The process is simply this:

    $ cd /path/to/project
    $ vagrant init  # Creates Vagrantfile

Now edit your `Vagrantfile` in order to tell Vagrant which flavor of Linux to install. Set the following options:

	> config.vm.box = "precise64"      # This likely says "base"
	> config.vm.box_url = "http://files.vagrantup.com/precise64.box"
This will install Ubuntu Server 12.04 (64 bit). That will [look just like this highlighted code](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-share-var-www-rb-L6-L8).

Save that and continue onward:

    $ vagrant up    # Starts the server
    # ... wait for it to bootup ...
    $ vagrant ssh   # Get into your new server!

Once you're in the new guest server, you can take a peak around. It doesn't do anything interesting yet, it's just like turning on a new, empty computer.

Within the guest virtual machine (once you are SSH'ed in), go into the `/vagrant` directory:

	cd /vagrant

Any file you create here will appear on your host computer as well! Conversely, any file added to the directory containing the `Vagrantfile` will also be available inside the guest machine. This is a **shared** folder that Vagrant sets up automatically. This lets you edit files on your host computer as you would normally, while also allowing the guest server access and run those files.

> Are you troubled by the need to use your Terminal? You'll get used to this! [Check this out](http://lifehacker.com/5633909/who-needs-a-mouse-learn-to-use-the-command-line-for-almost-anything) if you need a primer on basic commands.

For more on this process, see [this pretty simply guide](https://gist.github.com/dergachev/3866825), which roughly follows the same process. You can follow that up until it talks about Chef.


## Vagrant: Level 2

As noted, Vagrant let's you edit files directly on your computer (the host), rather than inside the virtual machine (the guest). By default, your computer's directory containing the `Vagrantfile` will be shared and mapped to the `/vagrant` directory in the guest server.

In our setup, however, we'll change this to share the `/var/www` folder in the server, which is where Apache reads its web files by default. In this way, any files added to your `Vagrantfile` directory will be available to the Apache web server!

[Here's the file-sharing configuration](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-share-var-www-rb-L12) to do that. We simply change `/vagrant` to `/var/www`. The `.` means "share this directory" (the one containing the `Vagrantfile`), and you can see it's being shared with `/var/www`. The next time the server is started, those settings will take effect.

If your server is running already, use `vagrant reload` to restart it using your new settings. You can also use `vagrant halt` to shut down the server when not in use, and use `vagrant up` to start it back up.

## Vagrant: Level 3

After you get a basic server and file sharing up and running, you'll need to do something with it! This is where you'll be in the Terminal quite a bit, which is why most tutorials turn to Chef, Puppet, Ansible or other tools for installing stuff for you. **You don't learn much that way, and those tools are complicated**. Let's do some learning.

Once again, get "inside" of the server by running `vagrant ssh`. Once you're in, follow [this guide to install a basic LAMP stack](http://fideloper.com/ubuntu-install-php54-lamp). Once that's all installed, you should be able to get the **It Works!** screen on your browser by going to `http://localhost:8080`. Since we're sharing the `/var/www` folder in the guest with our host computer, any file you add to the project directory will be also be available in your web server! Try creating the file `info.php`, and adding `<?php phpinfo();` to it. If you head to `http://localhost:8080/info.php`, you'll see the PHP information display.

## Vagrant: Level 4

Vagrant sets up a [forwarding mechanism](http://docs.vagrantup.com/v2/networking/forwarded_ports.html) so you can use `localhost:8080` in your browser to view your Vagrant web server. Alternatively, you can [configure Vagrant to setup a static IP address of your choosing](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-share-var-www-rb-L10). Then you can use the IP address in the browser instead of the forwarded `localhost:8080`. I also often use [xip.io](http://xip.io), which let's use addresses such as `http://myproject.192.168.33.10.xip.io` (where 192.168.33.10 is the IP address I happen to give my Vagrant server). This way you can setup separate projects within the same server, and differentiate them by subdomain (`myproject` being the subdomain in this example).

Don't forget to restart your server after any `Vagrantfile` configuration changes. You can use `vagrant reload` on your computer's terminal to both restart and enable any configuration changes made to the `Vagrantfile`.

## Wrapping Up

**tl;dr:** This **entire process** is outlined [in this gist](https://gist.github.com/fideloper/8622731). Pay attention to the comments in that file, they have extra instructions.

Curious about how to install other things? Check out [Vaprobash](https://github.com/fideloper/Vaprobash), which is a collection of bash scripts you can copy and paste from in order to install many popular server software packages. Some are more complicated than others, but they're all just commands run just like we're doing in our terminal here.

## More Resources:

* [The entire process above](https://gist.github.com/fideloper/8622731) is in this gist.
* [Excellent slides](https://speakerdeck.com/erikaheidi/vagrant-for-php-developers) on getting started with Vagrant
* [NetTuts on Vagrant](http://net.tutsplus.com/tutorials/php/vagrant-what-why-and-how/), with a little Puppet
* [NetTuts on Vagrant](http://net.tutsplus.com/tutorials/setting-up-a-staging-environment/) for setting up a staging environment
* [Gist to use to install LAMP stack](https://gist.github.com/fideloper/7074502), requiring no user input. Use it [like this](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-rb-L18) highlighted code.


---

<a name="configuring-apache-virtual-hosts" id="configuring-apache-virtual-hosts"></a>

# Configuring Apache Virtual Hosts

If you're using Apache for your development server, knowing how to configure Apache will be important.

Because you might run multiple sites on one Apache server, you need to tell Apache which directory contains the web files (the "web root" or "document root") per website.

First, here's **[a primer on Virtual Hosts](http://fideloper.com/ubuntu-prod-vhost)**, which will be most useful for Vagrant users installing Ubuntu.

If you need more information, check [the documentation](https://httpd.apache.org/docs/2.4/vhosts/). Luckily, it's fairly easy to understand once you know the files to edit. Most comment setups for virtual hosts include [name-based](https://httpd.apache.org/docs/2.4/vhosts/name-based.html), in which you differentiate virtual hosts via `ServerName`. However you can also [use IP addresses](https://httpd.apache.org/docs/2.4/vhosts/ip-based.html) to differentiate.

Finally, there are [examples of common setups](https://httpd.apache.org/docs/2.4/vhosts/examples.html)!

Not using Ubuntu or Debian? Here are guides for [CentOS](https://www.digitalocean.com/community/articles/how-to-set-up-apache-virtual-hosts-on-centos-6), [RedHat](https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Reference_Guide/s1-apache-virtualhosts.html), [FreeBSD](http://www5.us.freebsd.org/doc/handbook/network-apache.html#AEN39491) and [Arch](https://www.digitalocean.com/community/articles/how-to-set-up-apache-virtual-hosts-on-arch-linux).

## The Hosts File

You might also need this. Every computer has a `hosts` file. This file can tell your computer what server to use when you request a specific domain.

For example, if you set a virtual host for url `myproject.local`, your browser won't know what server to send that request to. However, if you also know your server's IP address is `192.168.33.10`, then you can edit your hosts file and add the entry `192.168.33.10  myproject.local`, which informs it where to look when that URL is used.

Here's how to [edit the hosts file on mac](http://osxdaily.com/2012/08/07/edit-hosts-file-mac-os-x/) and two methods for [editing hosts file (as an administrator) on Windows](http://www.petri.co.il/edit-hosts-file-windows-8.htm).

Personally, I've started using [xip.io](http://xip.io), which will map to the IP address given in the URL. This way, you can setup a virtual host with a `ServerName` such as `myproject.192.168.33.11.xip.io`, and use `http://myproject.192.168.33.11.xip.io` in your browser to go to the server. Note that the IP address I used would be the address of your Vagrant server. This lets you avoid editing your hosts file!


## More Resources

* [Upgrading from Apache 2.2 to 2.4](http://httpd.apache.org/docs/2.4/upgrading.html). Some servers still install 2.2, however some install the newer 2.4. If you find yourself suddenly using 2.4, know that it comes with some changes in configuration. The above article outlines those.
* My [vhost tool](https://gist.github.com/fideloper/2710970) script and the [comment on usage](https://gist.github.com/fideloper/2710970#comment-993649), in both Python and Bash flavors. For Ubuntu specifically. This creates and enables an Apache virtual host for you.

## Bonus

Here's a screencast covering more on Apache Virtual Hosts.

<iframe src="//player.vimeo.com/video/87364924" width="100%" height="517" style="width:100%" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

---
