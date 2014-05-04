---
title: Proxying to FastCGI in Ubuntu/Apache 2.4
descr: This will cover differences in passing requests off from Apache to a FastCGI process in Ubuntu 12.04 and 14.04
---
<p></p>
> My Vagrant project [Vaprobash](https://github.com/fideloper/Vaprobash) is undergoing updates for Ubuntu 14.04 LTS from Ubuntu 12.04 LTS. The following will outline one of the changes made between handling PHP with Apache, and the reasons/considerations made.

## Ubuntu 12.04

In Apache under Ubuntu 12.04 LTS, to pass a request off to a FastCGI process (such as PHP-FPM), I usually installed `libapache2-mod-fastcgi`. It looked something like this:

	$ sudo add-apt-repository -y ppa:ondrej/apache2
	$ sudo apt-key update
	$ sudo apt-get update
	$ sudo apt-get install -y apache2 apache2-mpm-event libapache2-mod-fastcgi

This would let us use one configuration file for handling FastCGI requests. For example, to hand off requests to PHP-FPM, I'd create `/etc/apache2/conf-available/php5-fpm.conf`:

    <IfModule mod_fastcgi.c>
            AddHandler php5-fcgi .php
            Action php5-fcgi /php5-fcgi
            Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
            FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization
            <Directory /usr/lib/cgi-bin>
                    Options ExecCGI FollowSymLinks
                    SetHandler fastcgi-script
                    Require all granted
            </Directory>
    </IfModule>

Once this was enabled (via a symlink to `/etc/apache2/conf-enabled/php5-fpm.conf`), PHP requests would be handed off to the PHP-FPM process listening on the unix socket `/var/run/php5-fpm.sock`.

## Ubuntu 14.04

In Ubuntu 14.04, the `libapache2-mod-fastcgi` module isn't available by default (nor with the [ondrej/apache2 repository](https://launchpad.net/~ondrej/+archive/apache2)). This is because it's part of the "[Multiverse" repositories](https://help.ubuntu.com/community/Repositories/Ubuntu), which are [not available by default](http://serverfault.com/questions/395139/cant-install-fastcgi-ubuntu-server-package-libapache2-mod-fastcgi-is-not-availa).

We can still that module, however. To do so, [edit `/etc/apt/sources.list`](http://askubuntu.com/questions/259590/libapache2-mod-fastcgi-not-available) and add the following repositories:

	deb http://archive.ubuntu.com/ubuntu trusty multiverse
	deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
	deb http://security.ubuntu.com/ubuntu trusty-security multiverse

Then you can run `sudo apt-get update && sudo apt-get install libapache2-mod-fastcgi` to install and use those modules, just like we did in Ubuntu 12.04.

### "Simpler" Method:

Instead of going through those hoops, however, let's use what Apache2 **does** come with in Ubuntu 14.04: `mod_proxy` and `mod_proxy_fcgi`. Working together, these modules can accomplish the same as the third-party `libapache2-mod-fastcgi`.

For the sake of not using unsupported and as few third-party modules as necessary, I've chosen to use `mod_proxy` and `mod_proxy_fcgi`. Overall, this comes with a simpler configuration as well, and a very similar configuration can be used for passing requests off to HHVM and even non-PHP applications.

Here's what the process of using those modules looks like:

#### Install PHP-FPM

This example will use PHP-FPM as the fastCGI process. Let's install that:

	$ sudo apt-get install php5-fpm

Our setup will now need PHP5-FPM to listen over a TCP socket instead of a unix socket. This means changing some configuration - this one-liner will do the trick:

	$ sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf

Instead of having PHP-FPM listen on the unix socket `/var/run/php5-fpm.sock`, it will listen on `127.0.0.1:9000` (you can use whichever port you need).

#### Configure Apache

First, if you need to, install Apache:

	$ sudo add-apt-repository -y ppa:ondrej/apache2
	$ sudo apt-key update
	$ sudo apt-get update
	$ sudo apt-get install -y apache2  # May need --force-yes

For Apache, we just need to enable `mod_proxy_fcgi` and add a configuration into our VirtualHost:

	$ sudo a2enmod proxy_fcgi

Our virtualhost might look something like this:

	<VirtualHost *:80>
		ServerName localhost
		DocumentRoot /var/www/html
		
		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined
	</VirtualHost>

With `mod_proxy`, we can simply add a line to our VirtualHost so PHP processes are proxied off to PHP-FPM:

	ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/$1

The **full VirtualHost** in this example would look like this:

	<VirtualHost *:80>
		ServerName localhost
		DocumentRoot /var/www/html
		
		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined
		
		ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/$1
	</VirtualHost>

Let's restart Apache so both the enabled module and the edited VirtualHost take effect:

	$ sudo service apache2 restart

Then any php file in `/var/www/html` will be handled by PHP-FPM!

## Resources
* [What is FastCGI](http://en.wikipedia.org/wiki/FastCGI)
* [Explaining Ubuntu Repositories](https://help.ubuntu.com/community/Repositories/Ubuntu)
* [About apache2-mpm-worker](http://stackoverflow.com/questions/13883646/apache-prefork-vs-worker-mpm)
* [mod_proxy docs](http://httpd.apache.org/docs/2.2/mod/mod_proxy.html#proxypassmatch)
* [mod_proxy_fcgi docs](https://httpd.apache.org/docs/trunk/mod/mod_proxy_fcgi.html)