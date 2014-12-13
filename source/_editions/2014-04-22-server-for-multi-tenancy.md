---
title: Server Setup for Multi-Tenancy Applications
topics: [Server Setup for Multi-Tenancy Applications]

---

For those of you making an application which supports multi-tenancy, here's some web server configurations you might find handy. A multi-tenancy application in this case is an application who has one code base but supports many organizations/tenants. This typical of many SaaS applications.

One common way to divide up users (or "organizations") with an application is to use subdomains. For example, [beanstalkapp.com](http://beanstalkapp.com) uses subdomains in such a way. Each organization can have many users. So, for organization "FooBar", the Beanstalkapp domain where users would log into would be [http://foobar.beanstalkapp.com](http://foobar.beanstalkapp.com).

Now, to do this, we likely want to use the same code base for the entire application. From a web server point of view, this means we want to create a virtual host which can match a wildcard subdomain, so we can have the same application code handle the request. Let's see how to do that in Apache and Nginx.

## Apache

For this Apache example, we'll create a virtual host for our marketing site (assuming it's not part of your main application code) and one virtual host for our application.

```conf
# The order of the VHosts is important

# Marketing Site
<VirtualHost *:80>

ServerName myapp.io;
ServerAlias www.myapp.io;

DocumentRoot /var/www/marketing-site

</VirtualHost>
```

The above is just a virtual host like any other. It handles `myapp.io` and `www.myapp.io` requests via the `ServerName` and `ServerAlias` directives respectively. (The above virtual host isn't complete, you may need to add in some [extra directives](https://gist.github.com/fideloper/9004209/#file-vhost-conf-L6-L18)).

```conf
# App Site
<VirtualHost *:80>

ServerName app.myapp.io;
ServerAlias *.myapp.io;

DocumentRoot /var/www/app-site

</VirtualHost>
```

This virtual host handles a base `ServerName` of `app.myapp.io` (you may or may not want to use that yourself) and then uses `ServerAlias` to match a wildcard subdomain. This directs to a separate DocumentRoot than the marketing site.

If you're using [Apache in front of a FastCGI process](http://www.failover.co/blog/quick-setup-apache-worker-fastcgi-php-fpm-and-apc) (simlar to an Nginx setup), you can easily just pass off this request to that as well. That would allow you to combine the previous two virtual hosts into one.


## Nginx

Nginx can have a similar setup.

```conf
# Marketing Site
server {
    listen 80;

    server_name www.myapp.io myapp.io

    root /var/www/marketing-site

}
```

The above server block can be used for a marketing home page. Again, it's just a regular old virtual server for Nginx. Nothing special here - it's setup for `www.myapp.io` and `myapp.io` domains. (You likely want to [use more directives in there](https://www.digitalocean.com/community/articles/how-to-set-up-nginx-virtual-hosts-server-blocks-on-ubuntu-12-04-lts--3#StepFive—SetUptheVirtualHosts) - the above example is abbreviated to show only what's necessary).

```conf
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
		include fastcgi_params; # fastcgi.conf for version 1.6.1+
	}
}
```

In this server block, we match a wildcard subdomain. As a bonus, we capture it as well as a `$user` variable, and can pass that off to our application using a `fastcgi_pass` directive. This will then become available as an environment variable in our application.

> These virtual hosts aren't necessarily complete. Check out the edition on [Apache virtual hosts](/editions/2014/02/25/vagrant-apache#configuring-apache-virtual-hosts) and [using Nginx](/editions/2014/03/25/nginx) to get more details on what should go in there.


## Resources

[This screencast](https://vimeo.com/89267501) on [this previous edition about Nginx](http://serversforhackers.com/editions/2014/03/25/nginx/) explains how to setup a wildcard subdomain in Nginx so you can match your document root to your subdomain as well. Try combining the above techniques to use `xip.io` and have it automatically match to a project directory!
