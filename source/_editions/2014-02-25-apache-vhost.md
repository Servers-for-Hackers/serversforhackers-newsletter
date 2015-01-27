---
title: Configuring Apache Virtual Hosts
topics: [Configuring Apache Virtual Hosts]
description: Learn what's going on inside of a basic Apache VirtualHost.
---

If you're using Apache for your development server, knowing how to configure Apache will be important.

Because you might run multiple sites on one Apache server, you need to tell Apache which directory contains the web files (the "web root" or "document root") per website.

## A Primer on Virtual Hosts

Virtual hosts are the bread and butter of Apache. They allow you to run multiple websites off of one web server as well as customize settings for each site.

### Setup

In Ubuntu, virtual hosts are setup to work by default. Any file you add to **/etc/apache2/sites-enabled** will be read.

By convention, Ubuntu uses two directories for virtual hosts. **/etc/apache2/sites-available** and **/etc/apache2/sites-enabled**. Sites-enabled contains symlinks to sites-available. In this way, you can have configurations for sites saved in sites-available, but disabled (By removing the symlink from the sites-enabled directory).

### Jumping Ahead a Bit

Let's say you have a virtual host configuration (test.com.conf) setup in `/etc/apache2/sites-available/test.com.conf`. This is not yet enabled.

```shell
$ sudo a2ensite test.com.conf  #Create symlink in sites-enabled to test.com.conf in sites-available
$ sudo service apache2 reload #Reload apache config so it's aware of new virtual host
```

Now, let's disable that:

    $ sudo a2dissite test.com.conf  #Remove symlink
    $ sudo service apache2 reload

So, now we know how to enable or disable a virtual host. Now let's go over some useful configurations.

### Virtual Host Config Files

Your best bet for a starting place is to copy Apache's default `/etc/apache/sites-available/default`. (Note that I like to make my files with the extension ".conf" - That's not necessary). I'm going to assume we'll make a server which will match the url `http://myproject.192.168.33.10.xip.io`. 

This assumes my server's IP address is `192.168.33.10`. Change yours as needed. I'm using [http://xip.io] as it lets me skip needing to do any extra setup (like having to edit my computer's [hosts file](http://en.wikipedia.org/wiki/Hosts_(file)).

```
$ sudo cp /etc/apache2/sites-available/000-default.conf \
          /etc/apache2/sites-available/myproject.conf
```

Here's what's in there.

```conf
<VirtualHost *:80>
    # The ServerName directive sets the request scheme, hostname and port that
    # the server uses to identify itself. This is used when creating
    # redirection URLs. In the context of virtual hosts, the ServerName
    # specifies what hostname must appear in the request's Host: header to
    # match this virtual host. For the default virtual host (this file) this
    # value is not decisive as it is used as a last resort host regardless.
    # However, you must set it for any further virtual host explicitly.
    #ServerName www.example.com

    ServerAdmin webmaster@localhost
    DocumentRoot /var/www

    # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
    # error, crit, alert, emerg.
    # It is also possible to configure the loglevel for particular
    # modules, e.g.
    #LogLevel info ssl:warn

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    # For most configuration files from conf-available/, which are
    # enabled or disabled at a global level, it is possible to
    # include a line for only one particular virtual host. For example the
    # following line enables the CGI configuration for this host only
    # after it has been globally disabled with "a2disconf".
    #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
```

Unlike Apache 2.2, Apache 2.4's default virtual host setup has less meat in there. We can add to that for our own default. Let's start here. Remove those unnecessary comments an get to where your new virtual host looks like this:

```conf
<VirtualHost *:80>
    ServerName myproject.192.168.33.10.xip.io

    DocumentRoot /var/www/myproject/public

    <Directory /var/www/myproject/public>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/myproject-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog ${APACHE_LOG_DIR}/myproject-access.log combined

</VirtualHost>
```

### What does all this do?

1. **[ServerName](http://httpd.apache.org/docs/2.4/mod/core.html#servername) and [ServerAlias](http://httpd.apache.org/docs/2.4/mod/core.html#serveralias):** Let Apache know the domain to match to this virtual host by setting the ServerName. Optionally also use **ServerAlias** to tell apache to listen to other domains and point them to this virtual host as well, such as a "www" subdomain.
2. **[DocumentRoot](http://httpd.apache.org/docs/current/mod/core.html#documentroot):** Change to suit your needs. I often have a "public_html" or "public" directory which is the web root. Then I can encapsulate related files which stay behind the web-root within the sites directory. (site.com directory, with site.com/public_html directory as the web-root). This is how Laravel works by default.
3. **[Options](http://httpd.apache.org/docs/current/mod/core.html#options) -Indexes:**: `-Indexes` stops people from being able to go to a directory and see files listed in there. Instead they see a Forbidden error. This can stops users view all your files in your `/images` directory, for instance. 
4. **[AllowOverride](http://httpd.apache.org/docs/current/mod/core.html#allowoverride)**: Set to "all" to allow `.htaccess` files in your virtual host (And sub-directories)
5. **[ErrorLog](http://httpd.apache.org/docs/current/mod/core.html#errorlog), [CustomLog](http://httpd.apache.org/docs/2.4/mod/mod_log_config.html#customlog):** Create log files specifically for your domain, so they don't get mixed in with traffic / errors from other sites running on the server.

## The Hosts File

You might also need this. Every computer has a `hosts` file. This file can tell your computer what server to use when you request a specific domain.

For example, if you set a virtual host for url `myproject.local`, your browser won't know what server to send that request to. However, if you also know your server's IP address is `192.168.33.10`, then you can edit your hosts file and add the entry `192.168.33.10  myproject.local`, which informs it where to look when that URL is used.

Here's how to [edit the hosts file on mac](http://osxdaily.com/2012/08/07/edit-hosts-file-mac-os-x/) and two methods for [editing hosts file (as an administrator) on Windows](http://www.petri.co.il/edit-hosts-file-windows-8.htm).

Personally, I've started using [xip.io](http://xip.io), which will map to the IP address given in the URL. This way, you can setup a virtual host with a `ServerName` such as `myproject.192.168.33.11.xip.io`, and use `http://myproject.192.168.33.11.xip.io` in your browser to go to the server. Note that the IP address I used would be the address of your Vagrant server. This lets you avoid editing your hosts file!


## More Resources

* [Upgrading from Apache 2.2 to 2.4](http://httpd.apache.org/docs/2.4/upgrading.html). Some servers still install 2.2, however some install the newer 2.4. If you find yourself suddenly using 2.4, know that it comes with some changes in configuration. The above article outlines those.
* My [vhost tool](https://gist.github.com/fideloper/2710970) script and the [comment on usage](https://gist.github.com/fideloper/2710970#comment-993649), in both Python and Bash flavors. For Ubuntu specifically. This creates and enables an Apache virtual host for you.


If you need more information, check [the documentation](https://httpd.apache.org/docs/2.4/vhosts/). Luckily, it's fairly easy to understand once you know the files to edit. Most comment setups for virtual hosts include [name-based](https://httpd.apache.org/docs/2.4/vhosts/name-based.html), in which you differentiate virtual hosts via `ServerName`. However you can also [use IP addresses](https://httpd.apache.org/docs/2.4/vhosts/ip-based.html) to differentiate.

Here are some [examples of common setups](https://httpd.apache.org/docs/2.4/vhosts/examples.html)!

Not using Ubuntu or Debian? Here are guides for [CentOS](https://www.digitalocean.com/community/articles/how-to-set-up-apache-virtual-hosts-on-centos-6), [RedHat](https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Reference_Guide/s1-apache-virtualhosts.html), [FreeBSD](http://www5.us.freebsd.org/doc/handbook/network-apache.html#AEN39491) and [Arch](https://www.digitalocean.com/community/articles/how-to-set-up-apache-virtual-hosts-on-arch-linux).

## Bonus

Here's a screencast covering more on Apache Virtual Hosts.

<iframe src="//player.vimeo.com/video/87364924" width="100%" height="517" style="width:100%" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

---
