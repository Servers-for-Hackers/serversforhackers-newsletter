---
title: Load Balancing with Nginx
descr: Learn how to use Nginx as a load balancer!
---

Nginx is a powerful web server. Let's also see how it can be used as a load balancer.

Let's assume Nginx is already installed.

## Example Servers

Let's see an example Node.JS script, which will listen on three separate web addresses. This will simulate having three web servers to balance traffic between.

Real web servers might be other applications, Nginx, Apache or other services listening over HTTP.

```javascript
var http = require('http');

function serve(ip, port)
{
        http.createServer(function (req, res) {
            res.writeHead(200, {'Content-Type': 'text/plain'});
            res.end("There's no place like "+ip+":"+port+"\n");
        }).listen(port, ip);
        console.log('Server running at http://'+ip+':'+port+'/');
}

serve('127.0.0.1', 9000);
serve('127.0.0.1', 9001);
serve('127.0.0.1', 9002);
```

Save this file as `server.js` and then we can run it using `node server.js`.

## Configure Nginx

A basic configuration is really simple. Let's say we have our three node.js HTTP "servers" running, and we want to distribute requests amongst them. We can configure our Nginx like so:

```
# Define your "upstream" servers - the
# servers request will be sent to
upstream app_example {
    least_conn;                 # Use Least Connections strategy
    server 127.0.0.1:9000;      # NodeJS Server 1
    server 127.0.0.1:9001;      # NodeJS Server 2
    server 127.0.0.1:9002;      # NodeJS Server 3
}

# Define the Nginx server
# This will proxy any non-static directory
server {
    listen 80;
    server_name example.com www.example.com;

    access_log /var/log/nginx/example.com-access.log;
    error_log  /var/log/nginx/example.com-error.log error;

    # Browser and robot always look for these
    # Turn off logging for them
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { log_not_found off; access_log off; }

    # Search for existing file or directory, otherwise send the request to 
    # the @proxy block, which balances the request between the web servers
    location / {
        try_files $uri $uri/ @proxy;
    }

    # pass the request to the node.js server
    # with some correct headers for proxy-awareness
    location @proxy {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;

        proxy_pass http://app_example/;
        proxy_redirect off;

        # Handle Web Socket connections
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

The above Nginx setup proxies requests to three local node processes which are setup to accept HTTP requests and respond to them.

The configuration checks for URI given to see if it corresponds to a file in the `root`. If it finds them, it will serve them. Otherwise it sends the request to the `@proxy` block.

This will then send requests to the `app_example` upstream block. Node will use the `least_conn` algorithm to decide how to distribute traffic amongst the servers.

The `@proxy` block also sets headers such as `X-Real-Ip` and `X-Forwarded-For`, so downstream servers can accept the IP address and know the client's true IP address.

## More

In the [Servers for Hackers eBook](https://book.serversforhackers.com), you'll learn more about setting up Nginx for applications and load balancing, along with SSL setup.

You'll also learn how to use HAProxy as a load balancer, including distributing traffic with SSL certificates, and distributing non-HTTP traffic (such as MySQL read requests).


