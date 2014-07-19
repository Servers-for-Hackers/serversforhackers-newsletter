---
title: Using SSL Certificates with HAProxy
topics: [Overview, SSL Termination, SSL Pass-through]
description: Using HAProxy with SSL certificates, including SSL Termation and SSL Pass-Through
draft: true
---

<a name="overview"></a>
## Overview

If your application makes use of SSL certificates, then some decisions need to be made about how to use them with a load balancer.

A simple setup of one server usually sees a client's SSL connection being descrypted by the server receiving the request. Because a load balancer sits between a client and one or more servers, where teh SSL connection is decrypted becomes a concern.

As noted earlier, there are two main strategies.

SSL Termination is the practice of terminating/decrypting an SSL connection at the load balancer, and sending "regular" connections to the servers the load balancer is proxying to.

This means the load balancer is responsible for decrypting an SSL connection - a slow and CPU intensive process relative to accepting non-SSL requests.

This is the opposite of SSL Pass-Through, which sends the SSL connection to the proxied server to decrypt and handle.

With SSL-Pass-Through, the SSL connection is terminated at each proxied server, distributing the CPU load across your servers. However, you lose the ability to add or edit HTTP headers, as the connection is simply routed through the load balancer to the proxied servers. This means you lose the ability to get the `X-Forwarded-*` headers, potentially losing needed client information such as their IP address.

Which you choose is up to you and your application needs. SSL Termination is the most typical I've seen, but pass-thru is likely more secure. A combination, where SSL connections are terminated at the load balancer, adjusted as needed, and then proxied off to the backend servers as a new SSL connection may provide the best of both security and ability to send the client information. The trade off is more CPU power being used all-around, and a little more complexity in configuration.

> An older article of mine on the [consequences and gotchas of using load balancers](http://fideloper.com/web-app-load-balancing) explains these issues (and more) as well.

<a name="ssl_termination"></a>
## HAProxy with SSL Termination

We'll cover the most typical use case first - SSL Termination. As stated, we need to have the load balancer handle the SSL connection. This means having the SSL Certificate live on the load balancer server.

We saw how to create a self-signed certificate in a previous chapter. We'll re-use that informaion for setting up an SSL certificate for HAProxy to use. Keep in mind that for a production SSL Certificate (not a self-signed one), you won't need to generate or sign a certificate yourself - you'll just need to create a Certificate Signing Request (csr).

First, we'll create a self-signed certificate for `*.xip.io`, which is handy for demonstration purposes, and lets use one the same certificate when our server IP addresses might change while testing locally.

As this process is outlined in a [passed edition on SSL certificates](http://serversforhackers.com/editions/2014/04/08/ssl-certs/), I'll simple show the steps taken here:

	$ sudo mkdir /etc/ssl/xip.io
	$ sudo openssl genrsa -out /etc/ssl/xip.io/xip.io.key 1024
	$ sudo openssl req -new -key /etc/ssl/xip.io/xip.io.key -out /etc/ssl/xip.io/xip.io.csr
	> Country Name (2 letter code) [AU]:US
	> State or Province Name (full name) [Some-State]:Connecticut
	> Locality Name (eg, city) []:New Haven
	> Organization Name (eg, company) [Internet Widgits Pty Ltd]:SFH
	> Organizational Unit Name (eg, section) []:
	> Common Name (e.g. server FQDN or YOUR name) []:*.xip.io
	> Email Address []:

	> Please enter the following 'extra' attributes to be sent with your certificate request
	> A challenge password []:
	> An optional company name []:
	$ sudo openssl x509 -req -days 365 -in /etc/ssl/xip.io/xip.io.csr -signkey /etc/ssl/xip.io/xip.io.key -out /etc/ssl/xip.io/xip.io.crt

After the certificates are created, we need to create a `pem` file, which might also be called a `crt` file or `bundle`. A `pem` file is essentially just the certificate, the key and optionally certificate authorities concatenated into one file. In our example, we'll simply concatenate the certificate and key files together (in that order) to create a `xip.io.pem` file. This is HAProxy's prefered way to read an SSL certificate.

	$ sudo cat /etc/ssl/xip.io/xip.io.crt /etc/ssl/xip.io/xip.io.key > /etc/ssl/xip.io/xip.io.pem

When purchasing a real certificate, you won't necessarily get a `pem` file, you might instead get a `bundle`, `cert`, `cert`, `key` file or some similar name for the same concept. This [Stack Overflow answer](http://serverfault.com/questions/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file) explains that nicely.

In any case, once we have a `pem` file for HAproxy to use, we can adjust our configuration just a bit to handle SSL connections.

We'll setup our application to accept both `http` and `https` connections. Where we had this in the [last edition on HAProxy](http://serversforhackers.com/editions/2014/07/15/haproxy/):

```
frontend localnodes
		bind *:80
		mode http
		default_backend nodes
```

We can now add a binding to the SSL port 443, and let HAProxy know where the SSL certificates are:

```
frontend localhost
    bind *:80
    bind *:443 ssl crt /etc/ssl/xip.io/xip.io.pem
    mode http
    default_backend nodes
```

In the above example, we're using the backend "nodes". The backend, luckily, doesn't really need to change in any way. In [previous edition on HAProxy](http://serversforhackers.com/editions/2014/07/15/haproxy/), we had the backend like so:

```
backend nodes
    mode http
    balance roundrobin
    option forwardfor
    option httpchk HEAD / HTTP/1.1\r\nHost:localhost
    server web01 172.17.0.3:9000 check
    server web02 172.17.0.3:9001 check
    server web03 172.17.0.3:9002 check
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
```

Because the SSL connection is terminated at the Load Balancer, we're still sending regular HTTP requests to the backend servers. We don't need to change this configuration, as it works the same!

### SSL Only

If you'd like the site to be SSL-only, you can add a `redirect` directive to the frontend configuration:

```
frontend localhost
    bind *:80
    bind *:443 ssl crt /etc/ssl/xip.io/xip.io.pem
    redirect scheme https if !{ ssl_fc }
    mode http
    default_backend nodes
```

Above, we added the `redirect` directive, which will redirect from "http" to "https" if the connection was not made with an SSL connection. More information on [`ssl_fc` is available here](http://cbonte.github.io/haproxy-dconv/configuration-1.5.html#7.3.4-ssl_fc).

<a name="ssl_passthru"></a>
## HAProxy with SSL Pass-Through

With SSL Pass-Through, we'll have our backend servers handle the SSL connection, rather than the load balancer. The job of the load balancer then is simply to proxy a request off to its configured backend servers. Because the connection remains encrypted, HAProxy can't do anything with it other than redirect a request to another server.

In this setup, we need to use TCP mode over HTTP mode in both the frontend and backend configurations. HAProxy will treat the connection as just a stream of information to proxy to a server, rather than use its functions available for HTTP requests.

Here's what the frontend configuration might look like:

```
frontend localhost
    bind *:80
    bind *:443
    option tcplog
    mode tcp
    default_backend nodes
```

This still binds to both port 80 and port 443, giving the opportunity to use both regular and SSL connections.

As mentioned, to pass a secure connection off to a backend server without encrypting it, we need to use TCP mode (`mode tcp`) instead. This also means we need to set the logging to tcp instead of the default http (`option tcplog`). See more on [log formats](http://cbonte.github.io/haproxy-dconv/configuration-1.5.html#8.2) to see the difference between `tcplog` and `httplog`.

We need to tweak our backend configuration as well. Notably, we once again use TCP mode, and we remove some directives to reflect the loss of functionality we'd be able to put into place with SSL Termination:

```
backend nodes
    mode tcp
    balance roundrobin
    option ssl-hello-chk
    server web01 172.17.0.3:443 check
    server web02 172.17.0.4:443 check
```

As you can see, this is set to `mode tcp` - Both frontend and backend configurations need to be set to this mode.

We also remove `option forwardfor` and the `http-request` options - these can't be used in TCP mode (And we can't inject headers into a request that's encrypted).

For health checks, we can use `ssl-hello-chk` which checks the connection as well as its ability to handle SSL (SSLv3 specifically) connections.

In this example, I have two fictitious server backend which accept SSL certificates. If you've read the [edition SSL certificates](http://serversforhackers.com/editions/2014/07/15/haproxy/), you can see how to integrate them with Apache or Nginx in order to create a web server backend which handles SSL traffic. With SSL Pass-Through, no SSL certificates need to be created or used within HAproxy. The backend servers can handle SSL connections just as they would if there was only one server used in the stack without a load balancer.

## Resources

* HAProxy Official [blog post on SSL Termination](http://blog.haproxy.com/2012/09/10/how-to-get-ssl-with-haproxy-getting-rid-of-stunnel-stud-nginx-or-pound/)
* SO Question: ["What is a PEM file?"](http://serverfault.com/questions/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file)
* [Reading custom headers in Nginx](http://stackoverflow.com/questions/12431496/nginx-read-custom-header-from-upstream-server) - Not mentioned in this edition specifically, but useful in context of reading `X-Forwarded-*` headers sent to Nginx
* [So You Got Yourself a Load Balancer](http://fideloper.com/web-app-load-balancing), an article about considerations to make in your applications when using a load balancer.
