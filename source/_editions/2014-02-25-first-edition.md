---
title: First Edition!

---

This is the very first Servers for Hackers newsletter. As one of the main goals of this newsletter is to get those less experienced on the server side of things get their feet wet, we'll start with some basics.

First, we'll discuss getting off of MAMP (or WAMP/XAMP for that matter) and start using a Virtual Machine. Then we'll talk about configuring Apache virtual hosts, as it's commonly a next step after installing Apache. Finally, for those more comfortable with servers, I'll show how to get started PostgreSQL.

---

## Getting off of MAMP

There's a large number of PHP users who rely on their trust *AMP installs to "just work". Many need to go beyond default setups for certain frameworks or projects however. When you do, these tools break down due to their lack of standard installs. Macintoshes, for example don't come with all of the configuration or modules needed for modern applications (whether PHP, ruby or Python). MAMP especially causes issues when you need to run PHP on the command-line, for unit testing, running artisan commands or many other situations. WAMP/XAMP also suffer from not having a real linux-based shell available to use in conjunction with them.

When you start hitting these walls, it's time to leave *AMP behind and start using virtual machines. You'll never look back.

### Vagrant

[Vagrant](http://www.vagrantup.com) makes this an especially pleasant process. I suggest taking it slow. Many tutorials will go on and on about using provisioning systems like Puppet, Chef or Ansible. If you're new to this, ignore all of that.

After you install [Vagrant](http://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org) (there's no trick, just download and install!), you can open your terminal and run "vagrant init". All this does is creata a new file called **Vagrantfile**.

In that file, change two things. Set **config.vm.box** to "precise64" and **config.vm.box_url** to "http://files.vagrantup.com/precise64.box". Make sure the box_url line is uncommented as well. This will install Ubuntu Server 12.04 (64 bit). That will [look like this](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-L6-L8). Then run "vagrant up" in your terminal. That'll start up a virtual machine.

For more on this process, see [this pretty simply guide](https://gist.github.com/dergachev/3866825). You can follow that up until it talks about Chef. Are you troubled by the need to use your Terminal? You'll get used to this! [Check this out](http://lifehacker.com/5633909/who-needs-a-mouse-learn-to-use-the-command-line-for-almost-anything) if you need a primer on basic commands.

After you get a virtual machine up and running, you'll need to do something with it. This is where you'll be in the Terminal a bit, and it's why most tutorials turn to Chef, Puppet, Ansible or other tools for installing stuff for you. You don't learn much that way, and they're confusing.

Run "vagrant ssh" to get into your virtual machine. Once you run that, you'll be "inside" of the VM. Any command you run will be run in the VM. Once you're in, follow this guide to [install a basic LAMP stack](http://fideloper.com/ubuntu-install-php54-lamp). This will install php 5.5, despite what the article says. Once that's all installed, you should be able to get the "it works!" screen on your browser by going to http://localhost:8080. Vagrant sets up a [forwarding mechanism](http://docs.vagrantup.com/v2/networking/forwarded_ports.html) so you can use "localhost:8080" on your browser to get into the VM. Alternatively, you can [configure this to work with a static IP address of your choosing instead](https://gist.github.com/fideloper/dab171a2aa646e86b782#file-vagrantfile-L10). Then you can hit the IP address in the browser instead of the forwarded "localhost:8080".

Curious about how to install other things? Check out [Vaprobash](https://github.com/fideloper/Vaprobash, which is a collection of scripts you can copy and paste from in order to install many popular server things. Some are more complicated than others, but they're all just commands run just like we're doing in our terminal.

### More Resources:

* [Excellent slides](https://speakerdeck.com/erikaheidi/vagrant-for-php-developers) on getting started with Vagrant
* [NetTuts on Vagrant](http://net.tutsplus.com/tutorials/php/vagrant-what-why-and-how/), with a little Puppet



---

## Configuring Apache Virtual Hosts
This newsletter with cover things like user management and permissions, firewalls, LAMP stacks, apache, nginx, load balancers, proxies, nodejs, ruby, python, php, search engines, automating processes, handling log files, git, deployment, sql, nosql, development environments, provisioning, **the list can go on forever!**

This is for hackers, programmers, brogrammers and neckbeards ...well, maybe not the neckbeards...  who want to learn more about the common tasks required to setup, secure and otherwise use or abuse their servers.

---

## Getting Started with PostgreSQL
This newsletter with cover things like user management and permissions, firewalls, LAMP stacks, apache, nginx, load balancers, proxies, nodejs, ruby, python, php, search engines, automating processes, handling log files, git, deployment, sql, nosql, development environments, provisioning, **the list can go on forever!**

This is for hackers, programmers, brogrammers and neckbeards ...well, maybe not the neckbeards...  who want to learn more about the common tasks required to setup, secure and otherwise use or abuse their servers.

---