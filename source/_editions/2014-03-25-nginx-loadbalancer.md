---
title: Using Nginx as a Load Balancer
topics: [Using Nginx as a Load Balancer]
description: Configure Nginx to load balance between web nodes.
---

If you've seen how Nginx pass web requests off to another process (like we hand off web requests to php-fpm, unicorn or gunicorn), you may have realized that Nginx can also act as a load balancer. It can distribute web requests amongst group of other servers or processes.

Before you add a load  balancer to your stack, read up on [considerations you may need to make in your web application](http://fideloper.com/web-app-load-balancing). Some considerations outlined there:

* User Sessions can persist across connections to different servers (or don't need to)
* SSL considerations are met (what servers have the SSL certificate(s))
* User-uploaded files live in a central store rather than on the web server the user happened to connect to
* Your application is proxy-aware (Get's the correct client IP address, port and protocol)

After you've ensured your web application is setup for a distributed environment, you can then decide on a strategy for load balancing. Nginx offers these strategies:

* **Round Robin** - Nginx switches which server to fulfill the request in order they are defined
* **Least Connections** - Request is assigned to the server with the least connections (and presumably the lowest load)
* **Ip-Hash/Sticky Sessions** - The Client's IP address is hashed. Ther resulting hash is used to determine which server to send the request to. This also makes user sessions "sticky". Subsequent requests from a specific user always get routed to the same server. This is one way to get around the issue of user sessions behaving as expected in a distributed environment.
* **Weight** - With any of the above strategies, you can assign weights to a server. Heavier-weighted servers are more likely to be selected to server a request. This is good if you want to use a partiuclarly powerful server more, or perhaps to use a server with newer or experimental specs/software installed less.

## Configuration

A basic configuration is really simple. Let's say we have three node.js processes running, and we want to distribute requests amongst them. We can configure our Nginx like so:

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

    # Handle static files so they are not proxied to NodeJS
    # You may want to also hand these requests to other upstream
    # servers, as you can define more than one!
    location ~ ^/(images/|img/|javascript/|js/|css/|stylesheets/|flash/|media/|static/|robots.txt|humans.txt|favicon.ico) {
      root /var/www;
    }

    # pass the request to the node.js server
    # with some correct headers for proxy-awareness
    location / {
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

# Let's do an SSL setup also
server {
    listen 443;

    # You'll need to have your own certificate and key files
    # This is not something to blindly copy and paste
    ssl on;
    ssl_certificate     /etc/ssl/example.com/example.com.crt;
    ssl_certificate_key /etc/ssl/example.com/example.com.key;

    # ... the rest here would be just like above ...
}
```

The above Nginx setup proxies requests to three local node processes which are setup to accept HTTP requests and respond to them.

**Note** that the configuration also checks for locations of **static** files. Rather than hand off static files for our Node processes to handle, Nginx handles the static requests itself.

If you needed to, you could also define *another* block of Upstream servers to handle static files. That way the Nginx server would purely be a load balancer.

If you want to see the test Node.js server's I used for this to follow along, they are as follows. I had the following in a `server.js` file:

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

## Resources

* Official docs on using [Nginx as load balancer](http://nginx.org/en/docs/http/load_balancing.html)
* Using Nginx as [image processor](http://leafo.net/posts/creating_an_image_server.html)  (and Hacker News [comments with more good info](https://news.ycombinator.com/item?id=6419064))
* Use [Nginx with Vaprobash](http://fideloper.github.io/Vaprobash/) for development