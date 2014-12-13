---
title: Getting Off of MAMP
topics: [Getting Off of MAMP]
description: We'll get off of MAMP, and into Vagrant, along with setting up Apache!
---

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