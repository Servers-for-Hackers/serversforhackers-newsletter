---
title: First Edition!

---

This is the very first Servers for Hackers newsletter. As one of the main goals of this newsletter is to get those less experienced on the server side of things get their feet wet, we'll start with some basics.

First, we'll discuss getting off of MAMP (or WAMP/XAMP for that matter) and start using a Virtual Machine. Then we'll talk about configuring Apache virtual hosts, as it's commonly a next step after installing Apache.

---

# Getting off of MAMP

There's a large number of PHP users who rely on their trusty *AMP installs to "just work". However, many need to go beyond default setups for certain frameworks or projects. When you do, these "easy" tools break down because the operating systems (and/or the [applications](http://stackoverflow.com/search?q=mamp+phpunit)) on which you work [break standards](http://stackoverflow.com/search?q=mamp+artisan) set by the Linux/Unix servers on which the projects likely will live in production.

When you start hitting these walls, it's time to leave *AMP behind and start using virtual machines to set up a "real" server. You'll never look back.

## Vagrant

[Vagrant](http://www.vagrantup.com) makes this an especially pleasant process. I suggest taking it slow. Many tutorials will go on and on about using provisioning systems like Puppet, Chef or Ansible. If you're new to this, ignore all of that.

After you install [Vagrant](http://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org) (there's no trick, just download and install!), you can open your terminal and run `vagrant init`. All this does is creata a new file called `Vagrantfile`.

In that file, change two things. Set **config.vm.box** to `precise64` and `config.vm.box_url` to `http://files.vagrantup.com/precise64.box`. Make sure the box_url line is uncommented as well. This will install Ubuntu Server 12.04 (64 bit). That will [look like this](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-L6-L8). Then run `vagrant up` in your terminal. That'll start up a server.

    $ cd /path/to/project
    $ vagrant init  # Creates Vagrantfile
    # ... Edit your Vagrantfile ...
    $ vagrant up    # Starts the server
    # ... wait for it to bootup ...
    $ vagrant ssh   # Get into your new server


For more on this process, see [this pretty simply guide](https://gist.github.com/dergachev/3866825). You can follow that up until it talks about Chef. Are you troubled by the need to use your Terminal? You'll get used to this! [Check this out](http://lifehacker.com/5633909/who-needs-a-mouse-learn-to-use-the-command-line-for-almost-anything) if you need a primer on basic commands.

## Setting Up a Web Server

After you get a server up and running, you'll need to do something with it. This is where you'll be in the Terminal quite a bit, which is why most tutorials turn to Chef, Puppet, Ansible or other tools for installing stuff for you. <strong>You don't learn much that way, and those tools are complicated</strong>.

Once get "inside" of the server by running `vagrant ssh`, any command you run will be executed in the server. Once you're in, follow this guide to [install a basic LAMP stack](http://fideloper.com/ubuntu-install-php54-lamp). This will install php 5.5, despite what the article says. Once that's all installed, you should be able to get the <strong>It Works!</strong> screen on your browser by going to `http://localhost:8080`.

Vagrant sets up a [forwarding mechanism](http://docs.vagrantup.com/v2/networking/forwarded_ports.html) so you can use `localhost:8080` to view your Vagrant web server. Alternatively, you can [configure Vagrant to setup a static IP address of your choosing](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-L10). Then you can use the IP address in the browser instead of the forwarded `localhost:8080`. I also often use [xip.io](http://xip.io), which let's use addresses such as `http://myproject.192.168.33.10.xip.xio` (where 192.168.33.10 is the IP address I happen to configure). This way you can setup separate projects within the same server, and diffrentiate them by subdomain (`myproject` in the xip.io url used here).

This entire process is outlined [in this gist](https://gist.github.com/fideloper/8622731).

Curious about how to install other things? Check out [Vaprobash](https://github.com/fideloper/Vaprobash), which is a collection of scripts you can copy and paste from in order to install many popular server things. Some are more complicated than others, but they're all just commands run just like we're doing in our terminal.

## More Resources:

* [The entire process above](https://gist.github.com/fideloper/8622731) is in this gist.
* [Excellent slides](https://speakerdeck.com/erikaheidi/vagrant-for-php-developers) on getting started with Vagrant
* [NetTuts on Vagrant](http://net.tutsplus.com/tutorials/php/vagrant-what-why-and-how/), with a little Puppet
* [NetTuts on Vagrant](http://net.tutsplus.com/tutorials/setting-up-a-staging-environment/) for setting up a staging environment
* [Gist to use to install LAMP stack](https://gist.github.com/fideloper/7074502), requiring no user input. Use it [like this](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-rb-L18).


---

# Configuring Apache Virtual Hosts

If you're using Apache for your development server, knowing how to configure Apache will be important.



## More Resources

* [About Apache Virtual Hosts](http://fideloper.com/ubuntu-prod-vhost) in Ubuntu. This will work nicely with the Vagrant information above.

---