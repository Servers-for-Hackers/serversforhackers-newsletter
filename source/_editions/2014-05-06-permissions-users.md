---
title: Permissions and User Management
topics: [Permissions, User Management]

---

<a name="permissions" id="permissions"></a>

## Permissions

* Directories
	* read - ability to read contents of a directory
	* write - ability to create a new file/dir within a directory
	* execute - ability to `cd` into a directory
* Files
	* read - ability to read a file
	* write - ability to write to a file
	* execute - ability to execute a file, such as a bash command

* User - The permission for owners of a file or directory to RWX
* Group - Users can be part of one or more groups. Groups can have their own set of permissions - this is the primary means for how multiple users can RWX the same sets of (common) files
* Other - The permissions for users who aren't the user or part of a group assigned to a file or directory

<!-- -->

	chmod [-R] guo[+-]rwx /path/to/dir/or/file

* g = group
* u = user
* o = other

* + = add permission
* - = remove permission

* r = read
* w = write
* x = execute

**Needs some explanation/examples**



<a name="user_management" id="user_management"></a>

## User Management

* Create User
* Assign Group (primary)
* Assign Group (secondary)
* Adm/sudo user
	* Including setup for passwordless login (?)

* Set group permissions, for "deploy" user (web user)
* Explain `www-data` often used in Ubuntu
* Change run user for apache/nginx (fpm?)

**Needs some explanation/examples**


