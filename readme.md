# Servers for Hackers

The simple website for the Servers for Hackers newsletter.


<!--
Notes:

A) Need 301 Redirects
B) Need to merge/move comments from Disqus

Redirects:

```
✔️ location = /editions/2014/02/25/vagrant-apache/ {
    return 301 $scheme://$host/getting-off-of-mamp/;
}

✔️ location = /editions/2014/03/11/logs/ {
    return 301 $scheme://$host/log-rotate/;
}

✔️ location = /editions/2014/03/25/nginx/ {
    return 301 $scheme://$host/nginx-loadbalancer/;
}

✔️ location = /editions/2014/04/22/hosts-dns-multi-tenancy/ {
    return 301 $scheme://$host/server-for-multi-tenancy/;
}

✔️ location = /editions/2014/06/17/more-security/ {
    return 301 $scheme://$host/firewall-auto-updating/;
}

✔ # Editions and Articles get combined
location ~ "^/(editions|articles)/[0-9]{4}/[0-9]{2}/[0-9]{2}/(?<mdfile>.*)/?$" {
    return 301 $scheme://$host/$mdfile;
}

✔️ # Emails are separate still
location ~ "^/emails/[0-9]{4}/[0-9]{2}/[0-9]{2}/(?<mdfile>.*)/?$" {
    return 301 $scheme://$host/emails/$mdfile;
}
```

✔️ /editions/2014/02/25/vagrant-apache/

✔️ * Getting off of MAMP (redirect to this one)
✔️ * Configuring Apache Virtual Hosts - grab content from: http://fideloper.com/ubuntu-prod-vhost
✔️ * Redirect http://fideloper.com/ubuntu-prod-vhost to this new page
✔️ * Redirect to new URLs
    * /apache-vhost/
    * /getting-off-of-mamp/
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/03/11/logs/

✔️ * All About Logs
✔️ * Managing Logs with Logrotate - grab content from: http://fideloper.com/ubuntu-prod-logrotate
✔️ * Redirect http://fideloper.com/ubuntu-prod-logrotate to this new page
✔️ * Redirect to new URLs
    * /all-about-logs/
    * /log-rotate/
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/03/25/nginx/

✔️ * Nginx as Frontman (+ wildcard subdomain video)
✔️ * Nginx as a Load Balancer
✔️ * Redirect to new URLs
    * /nginx-start/
    * /nginx-loadbalancer/
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/04/08/ssl-certs/

✔️ * SSL Overview
✔️ * Creating Self-Signed Cert (+ wildcard)
✔️ * Apache & Nginx Setup with SSL
✔️ * Redirect to new URLs
✔️ * MOVE DISQUS THREAD CORRECTLY
* NEW ARTICLE: Videos on setting up SSL in production


✔️ /editions/2014/04/22/hosts-dns-multi-tenancy/

✔️ * Hosts File and DNS (video "more on hosts files")
✔️ * Server Setup for Multi-Tenancy Applications
✔️ * Redirect to new URLs
    - /hosts-file-dns/
    - /server-for-multi-tenancy/
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/05/06/permissions-users/

✔️ * Permissions
✔️ * User Management
✔ * Redirect to new URLs
✔ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/05/20/copying-files/

✔️ * Copying Files Locally
✔️ * SCP: Secure Copy
✔️ * Rsync: Sync Files Across Hosts
✔️ * Redirect to new URLs
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/06/03/initial-security/

✔️ * Initial Security Setup (Basically secure user login/setup)
    - Overview
    - Initial User Setup
    - SSH Key Access
✔️ * Redirect to new URLs
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/06/17/more-security/

✔️ * More Security
    - Setting Up the Firewall: Iptables
    - Automatic Security Updates
✔️ * Redirect to new URL 
    * /firewall-auto-updating/
✔️ * MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/07/01/ssh-tricks/

✔️ * SSH Tricks
    - Logging In
    - SSH Config
    - SSH Tunneling
    - One-Off Commands
    - Ansible intro (one-off commands)
✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/07/15/haproxy/

✔️ * Load Balancing with HAProxy
    - Common Setups
    - Installation
    - Sample NodeJS Web Server
    - HAProxy Configuration
    - Monitoring HAProxy
✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/07/29/haproxy-ssl-termation-pass-through/

✔️ * Using SSL Certificates with HAProxy
    - Overview
    - HAProxy with SSL Termination
    - HAProxy with SSL Pass-Through
✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/08/12/process-monitoring/

✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/08/26/getting-started-with-ansible/

✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/09/09/nginx-caching/

✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/10/21/mailcatcher/

✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/11/04/pm2/

* Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY


✔️ /editions/2014/12/02/pgsql/

✔️ * Redirect to new URLs
✔️ MOVE DISQUS THREAD CORRECTLY

-->