---
title: Hosts File and DNS
topics: [Hosts File and DNS]

---

Let's say you want to use a domain for development on your local server. You have a virtual machine (perhaps Vagrant) or some server on which you'll be developing. If you want to reach this server by using the domain `project.dev`, how would you accomplish that?

Well we can't create or purchase this domain (so far as I know, the .dev TLD doesn't exist...yet). If we could, we would have to spend money (which sucks) and then manage the DNS for the domain, pointing the domain to the correct IP address.

If we typed in `http://project.dev` into our browser, the browser won't know what to do with it! There's no mechanism in place to tell the browser what IP address the domain should resolve to.

![project.dev before hosts file](https://s3.amazonaws.com/serversforhackers/project.dev.before.png)

What we need is a way to tell the browser that the domain `project.dev` points to some IP address. Luckily, all computers (in all OSes), have a `hosts` file. This file lets us map domains to IP addresses.

> [Here's a good article](http://www.rackspace.com/knowledge_center/article/how-do-i-modify-my-hosts-file) on finding/editing your hosts file for various operating systems.

What does a hosts file look like? Many usually have a few entries which point `localhost` to your local IP address `127.0.0.1`, and perhaps the [ipv6](http://en.wikipedia.org/wiki/IPv6) equivalent.

> Note that while we have a separate development server, we're editing the hosts file on the computer on which we want to use the project.dev domain. We're not editing the server's (or virtual machine's) hosts file.

On my Macintosh, it looks like this:

```
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1   localhost
255.255.255.255 broadcasthost
::1             localhost
fe80::1%lo0 localhost
```

How do we use this file to point a domain to our server? Luckily, it's easy! If our development server is on the IP address `192.168.22.10`, and we want to use the hostname `project.dev`, then we can simply append this entry to the hosts file:

```
192.168.22.10 project.dev
```

If we have multiple projects on this same server, each with their own domain, we can add each domain to this same entry:

```
192.168.22.10 project.dev project2.dev codename-orange.dev another.domain.dev
```

After saving your hosts file (and sometimes after [flushing your computers DNS cache](http://docs.cpanel.net/twiki/bin/view/AllDocumentation/ClearingBrowserCache)), you'll find these domains start to work - you can enter them into your browser or use them in SSH connections. The domains will resolve to the IP address you set!

> These changes will *only* work on the computer whose `hosts` file you edited.

![project.dev after hosts file](https://s3.amazonaws.com/serversforhackers/project.dev.after.png)

## Do I really have to edit my hosts file?

So what is our hosts file doing for us here? It's enabling us to circumvent the need to have any DNS services enabled for our domain. In other words, we don't need to pay for a domain nor setup/pay for a DNS service. For our one computer, we can edit the hosts file and be done with it.

**The hosts file is providing the service of telling our computer what IP address to resolve to when the domain is used.**

But there are services available which will let us skip having to edit our hosts file. [Xip.io](http://xip.io) is a service which can act like your hosts file. If you specify the IP address you'd like the `xip.io` domain to resolve to, it will do that for you!

For example, if I skip editing my hosts file and instead use [192.168.22.10.xip.io](http://192.168.22.10.xip.io), that will reach the server as well!

![xip.io](https://s3.amazonaws.com/serversforhackers/xip.io.default.page.png)

The service saw the IP address in the subdomain(s) of the `xip.io` address and resolved to it.

We can even use more subdomains with `xip.io`! For example, [whatever.i.want.192.168.22.10.xip.io](http://whatever.i.want.192.168.22.10.xip.io) will work just as well. This lets us use subdomains to differentiate between our projects, if they are hosted on the same server.

## Virtual Hosts

But perhaps you noticed that the `xip.io` address landed us on the default Apache site page, instead of our project page. The second part of this is making sure the virtual hosts on our webserver know what to do with the domain given.

**Do you see what's happening?** Editing your hosts file points the domain to the correct IP address, **but** your webserver at that IP address still needs to know what to do with that web request!

The other half of the equation is making sure our Apache or Nginx virtualhost detects the domain used and routes to the right site/webapp. It's not enough just to point a domain to our web server's IP address.

On **Apache**, we can edit our hosts file and do something like this:

```conf
<VirtualHost *:80>
	ServerName project.dev
	ServerAlias project.*.xip.io

	DocumentRoot /vagrant/project
</VirtualHost>
```

What's this doing? Well we set the site's primary domain as `project.dev`, in case we want to use that. If we want to use the domain `project.192.168.22.10.xip.io`, we set that up as the `ServerAlias`. Note that Apache can also use a wildcard `*` for the IP address. This is useful in case the IP address of your server changes.

If we later want to have another project on the same server, we can create another virtual host:

```conf
<VirtualHost *:80>
    ServerName project-two.dev
    ServerAlias project-two.*.xip.io

    DocumentRoot /vagrant/project-two
</VirtualHost>
```

In **Nginx**, we will do similarly:

```conf
server {
    listen: 80;

    server_name project.dev ~^project\.(.*)\.xip\.io;

    root /vagrant/project;

    index index.html index.htm;

    location / {
    	try_files $uri $uri/ /index.html;
    }
}
```

Here we have a similar setup. Using the [server_name](http://nginx.org/en/docs/http/server_names.html) directive, we can set up two domains. We have told it to respond to `project.dev`, as well as `project.*.xip.io`, using the above regex.

![wildcard xip.io](https://s3.amazonaws.com/serversforhackers/project.vhost.wildcard.png)

The **most important** point of the above steps is to know that simply pointing a domain to your server is not enough. In order for your web application to work, your web server also needs to know what to do with the incoming request. Since Apache and Nginx often (but not always) work based off of the domain used to reach it, we need to configure them as well. This is true for localhost servers, virtual machines and remote servers as well.

> You can use your hosts file to point real domains to another server. This is useful for testing an application as if it's "in production". Here's some more information on [uses for hosts files](http://www.bleepingcomputer.com/tutorials/hosts-files-explained/), and [here's some more](http://www.makeuseof.com/tag/6-surprising-uses-for-the-windows-hosts-file/).

## Resources

Here's an explanation of how to use your hosts file and [xip.io](http://xip.io).

<iframe src="//player.vimeo.com/video/92417152" width="100%" height="517" style="width:100%" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>