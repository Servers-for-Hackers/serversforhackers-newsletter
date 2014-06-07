---
title: More Security
topics: [Firewall, Security Updates]

---

In the last edition, we talked about some basic security setup for your new servers. In this edition, we'll add on to that! 

I still count this as basic security - things you should do when you first get your hands on a server. In fact, let's just call this "Initial Security Setup, Part II".

<a name="firewall" id="firewall"></a>

## Firewall

The firewall offers some really basic protections on your server - it's a very important tool. Unfortunately, iptables is the defacto firewall, and it's a little hard to pick up and use. Hopefully this will clear up a bit of how it works.

Basically, iptables is a list of rules that are checked against whenever a piece of data enters or leaves the server over a network. If traffic is allowed through, it goes through. If traffic is not allowed, the data packet is dropped.

Let's start head-first. Here's a basic list of rules we'll be building. This is some of the output from the command `sudo iptables -L -v`, which **l**ists the rules with some **v**erbosity. The following is for INPUT (in-bound traffic):

    target     prot opt in     out     source      destination
    ACCEPT     all  --  lo     any     anywhere    anywhere
    ACCEPT     all  --  any    any     anywhere    anywhere      ctstate RELATED,ESTABLISHED
    ACCEPT     tcp  --  any    any     anywhere    anywhere      tcp dpt:ssh
    ACCEPT     tcp  --  any    any     anywhere    anywhere      tcp dpt:http
    ACCEPT     tcp  --  any    any     anywhere    anywhere      tcp dpt:https
    DROP       all  --  any    any     anywhere    anywhere

These rules are followed in order, so the first found to handle the traffic will determine what happens to the data being checked.

Let's go over this list of rules we have for inbound traffic, in order of appearance:

1. Accept all traffic on "lo", the ["loopback" interface](http://askubuntu.com/questions/247625/what-is-the-loopback-device-and-how-do-i-use-it). This is essentially saying "Allow all **internal** traffic to pass through"
2. Accept all traffic from currently established connections and related (Typically set so you don't accidentaly block yourself from the server when editing firewall rules)
3. Accept TCP traffic ([vs UDP](https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=what%20is%20udp)) over port 22 (which iptables labels "ssh" by default). If you changed the default SSH port, this might have the port number instead
4. Accept TCP traffic over port 80 (which iptables labels "http" by default)
5. Accept TCP traffic over port 443 (which iptables labels "https" by default)
6. Drop anything and everything else

See how the last rule says to DROP all traffic? If a packet has passed all other rules without matching, it will reach this rule, which says to DROP the data. This means that we've only allowed current connections, SSH (tcp port 22), http (tcp port 80) and https (tcp port 443) traffic into our server! Everything else is blocked.

> The first rule that matches the traffic type (protocol, interface, source/destination and other types) will decide how to handle the traffic. Rules below a match are not tested.
> 
> If more than one rule match the traffic type, then the 2nd rule will never be reached.

So, we've effectively (for the most part) shut off our server from external connections unless they come from SSH, HTTP, or HTTPS tcp ports.

### Adding these rules

OK, so we need to know how to add these rules. You can check your current rules by running the following:

    $ sudo iptables -L -v

You'll see something like this:

    Chain INPUT (policy ACCEPT 35600 packets, 3504K bytes)
     pkts bytes target     prot opt in     out     source    destination         

    Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
     pkts bytes target     prot opt in     out     source    destination         

    Chain OUTPUT (policy ACCEPT 35477 packets, 3468K bytes)
     pkts bytes target     prot opt in     out     source    destination

What we see above three default chains of the filter table:

1. `INPUT` policy - Traffic inbound to the server
2. `FORWARD` policy - Traffic forwarded (routed) to other locations
3. `OUTPUT` policy - Traffic outbound from the server

> The ArchWiki has a great explanation on [Tables vs Chains vs Rules](https://wiki.archlinux.org/index.php/iptables). There are other tables/chains as well - see [NAT, Mangle and Raw tables](http://www.thegeekstuff.com/2011/01/iptables-fundamentals/)

Let's add to our Chain of rules by appending to the INPUT chain. First, we'll add a rule to allow all loopback traffic:

    sudo iptables -A INPUT -i lo -j ACCEPT

And as usual, we'll go over this command:

* `-A INPUT` - **A**ppend to the **INPUT** chain
* `-i lo` - Apply the rule to the **lo**opback **i**nterface
* `-j ACCEPT` - **J**ump the packet to the ACCEPT rule. Basically, accept the data packets. "ACCEPT" is a built-in target, but you can jump to user-defined ones as well, but that's getting advanced.

Now let's add the rule to accept current/established connections:

    sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

And the command explanation:

* `-A INPUT` - **A**ppend to the INPUT chain
* `-m conntrack` - **M**atch traffic using "connection tracking" module
* `--ctstate RELATED,ESTABLISHED` - Match traffic with the **state** "established" and "related"
* `-j ACCEPT` - Use the ACCEPT target; accept the traffic

The one's a little on the complex side - I'll post links to some explanatory resources, but won't focus on them here.

Let's start adding some *real* rules. We'll start by opening up our SSH port to remote access:

    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

And the command explanation:

* `-A INPUT` - **A**ppend to the INPUT chain
* `-p tcp` - Apply to the tcp **P**rotocol
* `--dport 22` - Apply to **d**estination port 22 (Incoming traffic coming into port 22).
* `-j ACCEPT` - Use the ACCEPT target; accept the traffic

If you check your rules after this with another call to `sudo iptables -L -v`, you'll see that "22" is labeled "ssh" instead. If you don't use port 22 for SSH, then you'll see the port number listed.

We can add a very simlar rule for HTTP traffic:

    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

And for our last rule, we'll add the "catch all" to DROP any packets which made it this far down the rule chain:

    sudo iptables -A INPUT -j DROP

And the command explanation:

* `-A INPUT` - **A**ppend to the INPUT chain
* `-j DROP` - Use the DROP target; deny the traffic

This is our first instance of "DROP" - we're simply dropping the network data packet instead of allowing it through to our server.

### Inserting Rules

So far we've seen how to **A**ppend rules (to the bottom of the chain). Let's see how to **I**nsert rules, so we can add rules in the middle of a chain.

We haven't yet added a firewall rule to allow HTTPS traffic (port 443). Let's do that:

    sudo iptables -I INPUT 4 -p tcp --dport 443 -j ACCEPT

And the command explanation:

* `-I INPUT 4` - **I**nsert into the INPUT chain at the fourth position
* `-p tcp` - Apply the rule to the tcp **p**rotocol
* `--dport 80` - Apply to the **d*estination port 443 (Incoming traffic coming into port 443).
* `-j ACCEPT` - Use the ACCEPT target; accept the traffic

### Deleting Rules

Let's say we want to change our SSH port from a non-standard port. We'd set that in `/etc/ssh/sshd_config` as explained in the [Initial Security Setup](/editions/2014/06/03/initial-security/) edition. Then we need to change the firewall rules to allow SSH traffic from port 22 to our new port (let's pretend 1234).

First, we'll delete the SSH rule (two ways):

    # Delete at position 3
    sudo iptables -D INPUT 3

    # Or delete by the rule:
    sudo iptables -D INPUT -p tcp --dport 22 -j ACCEPT

We can see that `-D` will delete the firewall rule. Otherwise we need to match either the position of the rule or all the conditions set when creating the rule to delete it.

Then we can insert our new SSH rule at port 1234:

    sudo iptables -I INPUT 3 -p tcp --dport 1234 -j ACCEPT

> This article covers ipv4 IP addresses, but iptables can handle rules for both [ipv4](http://en.wikipedia.org/wiki/IPv4) and [ipv6](http://en.wikipedia.org/wiki/IPv6).

### Saving Firewall Rules

By default, iptables doesn't save firewall rules after a reboot (they are saved in memory). We therefore need a way to save the rules and re-apply them on reboot.

1. Output rules to file
2. Restore rules to file
3. Install persistent and apply rules

## Automatic Updates

We want our server to run automatic security updates (skipping other upgrades which could break our software). Whether or not you consider this a best practice is up to you - perhaps security upgrades have potential to break your applications. Use this as you see fit.

1. https://help.ubuntu.com/14.04/serverguide/automatic-updates.html
2. https://bjornjohansen.no/get-your-vps-up-and-running
3. http://lattejed.com/first-five-and-a-half-minutes-on-a-server-with-ansible - Ansible

## More Resources:

* http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
* [Try out UFW](https://help.ubuntu.com/community/UFW), a wrapper for Iptables. More [here](https://help.ubuntu.com/14.04/serverguide/firewall.html) and [here](https://wiki.archlinux.org/index.php/Uncomplicated_Firewall).
* [Try out Shorewall](http://shorewall.net/shorewall_quickstart_guide.htm), an alternative to Iptables.
* [Logging dropped packets with iptables](http://fideloper.com/iptables-tutorial)
* [Persisting iptables rules on CentOS](https://www.centos.org/docs/5/html/5.1/Deployment_Guide/s1-iptables-saving.html)