---
title: Copying Files
topics: [Copying Files (remotely)]

---

After an awesome week at Laracon, I have a short (but sweet) edition Servers for Hackers to share. During Laracon, many people expressed gratitude for SFH and [Vaprobash](https://github.com/fideloper/vaprobash). I'm still taken aback - that's so awesome. I'm so glad this content is found to be so useful!

<a name="copying_files" id="copying_files"></a>

## Copying Files

So there's quite a few ways of copying files using the command line. Of course we can copy files inside of our own computer, but often **we need to copy files across servers**! There's a few strategies for doing so, which we'll cover here in a little more detail.

### Locally Copying Files

I suspect this is a boring part of the newsletter - I'll cover it quickly. We can use the `cp` command:

Copy a file:

    $ cp /path/to/source/file.ext /path/to/destination/

    # Or rename it
    $ cp /path/to/source/file.ext /path/to/destination/new-filename.ext

To copy a directory, we copy recursively with the `-r` flag:

    $ cp -r /path/to/source/dir /path/to/destination
    # Result: /path/to/destination/dir exists!

### SCP: Secure Copy

Secure Copy is the `cp` command, but secure. More importantly, it has the ability to send files to remote servers via SSH!

Copy a file or a remote server:

    # Copy a file:
    $ scp /path/to/source/file.ext username@hostname.com:/path/to/destination/file.ext

    # Copy a directory:
    $ scp -r /path/to/source/dir username@server-host.com:/path/to/destination

This will attempt to connect to `hostname.com` as user `username`. It will ask you for a password if there's no SSH key setup (or if you don't have a password-less SSH key setup between the two computers). If the connection is authenticated, the file will be copied to the remote server.

Since this works just like SSH (using SSH, in fact), we can add flags normally used with the SSH command as well. For example, you can add the `-v` and/or `-vvv` to get various levels of verbosity in output about the connection attempt and file transfer.

You can also use the `-i` (identity file) flag to specify an SSH identity file to use:

    $ scp -i ~/.ssh/some_identity.pem /path/to/source/file.ext username@hostname:/path/to/destination/file.ext

**Here are some other useful flags:**

* `-p` (lowercase) - Show estimated time and connection speed while copying
* `-P` - Choose an alternate port
* `-c` (lowercase) - Choose another cypher other than the default `AES-128` for encryption
* `-C` - Compress files before copying, for faster upload speeds (already compressed files are not compressed further)
* `-l` - Limit bandwidth used in kiltobits per second (8 bits to a byte!).
    * e.g. Limit to 50 KB/s: `scp -l 400 ~/file.ext user@host.com:~/file.ext`
* `-q` - Quiet output

### Rsync: Sync Files Across Hosts

Rsync is another secure way to transfer files. Rsync has the ability to detect file differences, giving it the opportunity to save bandwidth and time when transfering files.

Just like `scp`, rsync can use SSH to connect to remote hosts and send/receive files from them. The same (mostly) rules and SSH-related flags apply for rsync as well.

Copy a files to a remote server:

    # Copy a file
    $ rsync /path/to/source/file.ext username@hostname.com:/path/to/destination/file.ext

    # Copy a directory:
    $ rsync -r /path/to/source/dir username@hostname.com:/path/to/destination/dir

To use a specific SSH identity file and/or SSH port, we need to do a little more work. We'll use the `-e` flag, which lets us choose/modify the remote shell program used to send files.

    $ rsync -e 'ssh -p 8888 -i /home/username/.ssh/some_identity.pem' /source/file.ext username@hostname:/destination/file.ext

**Here are some other common [flags](http://linux.die.net/man/1/rsync) to use:**

* `-v` - Verbose output
* `-z` - Compress files
* `-c` - Compare files based on checksum instead of mod-time (create/modified timestamp) and size
* `-r` - Recursive
* `-S` - Handle [sparse files](http://gergap.wordpress.com/2013/08/10/rsync-and-sparse-files/) efficiently
* Symlinks:
    * `-l` - Copy symlinks as symlinks
    * `-L` - Transform symlink into referent file/dir (copy the actual file)
* `-p` - Preserve permissions
* `-h` - Output numbers in a human-readable format
* `--exclude=""` - Files to exclude
    * e.g. Exclude the .git directory: `--exclude=".git"`

There are many [other options](http://linux.die.net/man/1/rsync) as well - you can do a LOT with rsync!

**Do a Dry-Run:**

I often do a dry-run of rsync to preview what files will be copied over. This is useful for making sure your flags are correct and you won't overwrite files you don't with to:

For this, we can use the `-n` or `--dry-run` flag:

    # Copy the current directory
    $ rsync -vzcrSLhp --dry-run ./ username@hostname.com:/var/www/some-site.com
    #> building file list ... done
    #> ... list of directories/files and some meta data here ...

**Resume a Stalled Transfer:**

Once in a while a large file transfer might stall or fail (while either using `scp` or `rsync`). We can actually use rsync to finish a file transfer!

For this, we can use the `--partial` flag, which tells rsync to not delete partially transferred files but keep them and attempt to finish its transfer on a next attempt:

    $ rsync --partial --progress largefile.ext username@hostname:/path/to/largefile.ext

**The Archive Option:**

There's also a `-a` or `--archive` option, which is a handy shortcut for the options `-rlptgoD`:

* `-r` - Copy recursively
* `-l` - Copy symlinks as symlinks
* `-p` - Preserve permissions
* `-t` - Preserve modification times
* `-g` - Preserve group
* `-o` - Preserve owner (User needs to have permission to change owner)
* `-D` - Preserve [special/device files](http://en.wikipedia.org/wiki/Device_file). Same as `--devices --specials`. (User needs permissions to do so)

<!-- get out of list styles -->

    # Copy using the archive option and print some stats
    $ rsync -a --stats /source/dir/path username@hostname:/destination/dir/path

## Resources

* [Use ssh config](http://nerderati.com/2011/03/simplify-your-life-with-an-ssh-config-file/) for simpler SSH connections
* [Rsync manual page](http://linux.die.net/man/1/rsync)
* Rsync to [smartly merge directories](http://superuser.com/questions/547282/which-is-the-rsync-command-to-smartly-merge-two-folders)
* Rsync to [mirror data between servers](http://www.linuxquestions.org/linux/answers/Networking/Using_rsync_to_mirror_data_between_servers) - perhaps a simple solution for load balanced environments