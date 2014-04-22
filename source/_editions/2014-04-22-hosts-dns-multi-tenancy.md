---
title: Hosts File/DNS and Multi-Tenancy
topics: [Hosts File and DNS, Server Setup for Multi-Tenancy Applications]

---

<a name="dns_stuff" id="dns_stuff"></a>

## Hosts File and DNS

Let's say you want to use a domain for development on your local server. You have a virtual machine (perhaps Vagrant) or some server on which you'll be developing. If you want to reach this server by using the domain `project.dev`, how would you accomplish that?

Well we can't create or purchase this domain. If we could, we would have to spend money (which sucks) and then manage the DNS for the domain, pointing the domain to the correct IP address. This is normally how you handle "real" domains, but we're working in a development environment in this example.

If we typed in this development domain into our browser, it won't know what to do with it!

![project.dev before hosts file](https://s3.amazonaws.com/serversforhackers/project.dev.before.png)

What we need is to make our computer believe that the domain `project.dev` points to some IP address. Luckily, all computers (in all OSes), have a `hosts` file. This file lets us map domains to IP addresses.

> [Here's a good article](http://www.rackspace.com/knowledge_center/article/how-do-i-modify-my-hosts-file) on finding your hosts file.

What does a hosts file look like? Many simply have a few entries which point the "domain" `localhost` to your local IP address `127.0.0.1`, and perhaps the [ipv6](http://en.wikipedia.org/wiki/IPv6) equivalent.

On my Macintosh, it looks like this:

    # Host Database
    #
    # localhost is used to configure the loopback interface
    # when the system is booting.  Do not change this entry.
    ##
    127.0.0.1   localhost
    255.255.255.255 broadcasthost
    ::1             localhost
    fe80::1%lo0 localhost

How do we use this file to point a domain to our server? Luckily, it's easy! If our development server is on the IP address `192.168.22.10`, and we want to use the hostname `project.dev`, then we can simply append this entry to the hosts file:

	192.168.22.10 project.dev

If we have multiple projects on this same server, each with their own domain, we can add each domain to this same entry:

	192.168.22.10 project.dev project2.dev codename-orange.dev another.domain.dev

After saving your hosts file (and sometimes after [flushing your computers DNS cache](http://docs.cpanel.net/twiki/bin/view/AllDocumentation/ClearingBrowserCache)), you'll find these domains start to work - you can enter them into your browser or use them in SSH connections. The domains will resolve to the IP address you set!

> These changes will *only* work on the computer whose `hosts` file you edited.

![project.dev after hosts file](https://s3.amazonaws.com/serversforhackers/project.dev.after.png)

### Do I really have to edit my hosts file?

So what is our hosts file doing for us here? It's enabling us to circumvent the need to have any DNS services enabled for our domain. In other words, we don't need to pay for a domain and host any DNS services, like come with namecheap.com, godaddy.com, register.com and other places where you can purchase a domain.

**The hosts file is providing the service of telling our computer what IP address to resolve to when the domain is used.**

But there are other services available, which will let us skip having to edit our hosts file. One service is [xip.io](http://xip.io). Xip.io is a service which does what your hosts file does for you. If you specify the IP address you'd like the domain to resolve to, it will do that for you.

For example, if I skip editing my hosts file and instead use [192.168.22.10.xip.io](http://192.168.22.10.xip.io), that will reach the server as well!

![xip.io](https://s3.amazonaws.com/serversforhackers/xip.io.default.page.png)

We can even use more subdomains with xip.io. For example, [whatever.i.want.192.168.22.10.xip.io](http://whatever.i.want.192.168.22.10.xip.io) will work just as well. We can use different subdomains to differentiate between our projects.

### Virtual Hosts

But what do we notice here? This is our default site page, instead of our project page. The second part of this is making sure the virtual hosts on our webserver know what to do with the domain given.

You see what's happening? Editing your hosts file points the domain to the correct IP address, but your webserver at that IP address still needs to know what to do with that web request. The other half of the eqation is making sure our Apache or Nginx virtualhost detects the domain used and routes to the right site/webapp.

On Apache, we can edit our hosts file and do something like this:

	<VirtualHost *:80>
		ServerName project.dev
		ServerAlias project.*.xip.io
		
		DocumentRoot /vagrant
	</VirtualHost>

What's this doing? Well we set the site's primary domain as `project.dev`, in case we want to use that. If we want to use the domain `project.192.168.22.10.xip.xio`, we set that up as the `ServerAlias`. Note that Apache can also use a wildcard `*` for the IP address. This is useful in case the IP address of your server changes.

In Nginx, we will do similarly:

    server {
        listen: 80;
        
        server_name project.dev ~^project\.(.*)\.xip\.io;
        
        root /vagrant;
        
        index index.html index.htm;
        
        location / {
        	try_files $uri $uri/ /index.html;
        }
    }

Here we have a similar setup. One domain ([server_name](http://nginx.org/en/docs/http/server_names.html)) we can use for this virtual host is `project.dev`. We can also use `project.*.xip.io` using the above regex.

![wildcard xip.io](https://s3.amazonaws.com/serversforhackers/project.vhost.wildcard.png)

The **most important** point of the above steps is to know that simply pointing a domain to your server is not enough. In order for your web application to work, your web server also needs to know what to do with the incoming request. Since Apache and Nginx often (but not always) work based off of the domain used to reach it, we need to configure them as well. This is true for localhost servers, virtual machines and remote servers as well.

> You can use your hosts file to point real domains to another server. This is useful for testing an application as if its "in production". Here's some more information on [uses for hosts files](http://www.bleepingcomputer.com/tutorials/hosts-files-explained/), and [here's some more](http://www.makeuseof.com/tag/6-surprising-uses-for-the-windows-hosts-file/).


<a name="multitenancy" id="multitenancy"></a>

## Server Setup for Multi-Tenancy Applications

For those of you making an application which supports multi-tenancy, here's some web server configurations you might find handy. A multi-tenancy application in this case is an application who has one code base but supports many users. This is a typical SaaS application.

One common way to divide up a current user (or "organization") with an application is to use subdomains. For example, [beanstalkapp.com](http://beanstalkapp.com) uses subdomains to divide up organizations. Each organization can have many users. So, for organization "FooBar", their Beanstalkapp domain would be [http://foobar.beanstalkapp.com](http://foobar.beanstalkapp.com).

We likely want to use the same code base for the entire application. From a web server point of view, this means we want to create a virtual host which can match a wildcard subdomain, so we can have the same application code handle the request. Let's see how to do that in Apache and Nginx.

### Apache

For this Apache example, we'll create a virtual host for our marketing site (assuming one set of code file) and one virtual host for our application.

	# The order of the VHosts is important
	
	# Marketing Site
	<VirtualHost *:80>
	
	ServerName myapp.io;
	ServerAlias www.myapp.io;
	
	DocumentRoot /var/www/marketing-site
	
	</VirtualHost>

The above is just a virtual host like any other. It handles `myapp.io` and `www.myapp.io` requests via the `ServerName` and `ServerAlias` directives respectively. The above virtual host isn't complete, you may need to add in some [extra directives](https://gist.github.com/fideloper/9004209/#file-vhost-conf-L6-L18).
	
	# App Site
	<VirtualHost *:80>
	
	ServerName app.myapp.io;
	ServerAlias *.myapp.io;
	
	DocumentRoot /var/www/app-site
	
	</VirtualHost>

This virtual host handles a base `ServerName` of `app.myapp.io` (you may or may not want to use that yourself) and then uses `ServerAlias` to match a wildcard subdomain. This directs to a separate DocumentRoot than the marketing site, but if you're using [Apache in front of a FastCGI process](http://www.failover.co/blog/quick-setup-apache-worker-fastcgi-php-fpm-and-apc) (simlar to an Nginx setup), you can easily just pass off this request to that as well.


### Nginx

Nginx can have a similar setup.

    # Marketing Site
    server {
        listen 80;
        
        server_name www.myapp.io myapp.io
        
        root /var/www/marketing-site
        
    }

The above server block can be used for a marketing home page. Again, it's just a regular old virtual server for Nginx. Nothing special here (You likely want to [use more directives in there](https://www.digitalocean.com/community/articles/how-to-set-up-nginx-virtual-hosts-server-blocks-on-ubuntu-12-04-lts--3#StepFive—SetUptheVirtualHosts) - the above example is abbreviated to show only what's necessary).

    # App Site
    server {
    	listen 80;
    	
    	# Match *.myapp.io
    	server_name  ~^(?<user>.+)\.myapp\.io$;
    	
    	root /var/www/app-site
    	
    	# Optionally pass the subdomain to the app via
    	# fastcgi_param, so it's available as an
    	# environment variable
    	location / {
    		fastcgi_param  USER $user;
    		fastcgi_pass 127.0.0.1:9000;
    		include fastcgi_params;
    	}
    }

In this server block, we match a wildcard subdomain. As a bonus, we capture it as well as a `$user` variable, and can pass that off to our application using a `fastcgi_pass` directive. This will then become available as an environment variable in our application.

> These virtual hosts aren't necessarily complete. Check out the edition on [Apache virtual hosts](/editions/2014/02/25/vagrant-apache#configuring-apache-virtual-hosts) and [using Nginx](/editions/2014/03/25/nginx) to get more details on what should go in there.


## More on Hosts Files:

Here's a similar explanation of how to use your hosts file and [xip.io](http://xip.io), but in video format!

<iframe src="//player.vimeo.com/video/92417152" width="100%" height="517" style="width:100%" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>