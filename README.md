# Keyman

This simple little utility allows you to manage the authorized_keys files for a
number of servers & users. It is designed to provide easy access to ensure that
you can revoke & grant access to appropriate people on multiple servers.

## Installation

To install, just install the Rubygem.

```bash
$ gem install keyman
```

Once installed, you will need to create yourself a **manifest directory**. This
directory will contain all your configuration for your key manager. You should
create an empty directory and add two files, a `servers.km` and a `users.km` file.

## Example Users/Groups Manifest File

The below file is an example of a `users.km` manifest file.

```ruby
group :admins do
  user :adam, 'ssh-rsa AAAAB3NzaC1yc2EAAAA[...]=='
  user :charlie, 'ssh-rsa AAAAB3NzaC1yc2EAAAA[...]=='
  user :nathan, 'ssh-rsa AAAAB3NzaC1yc2EAAAA[...]=='
end

group :staff do
  user :jack, 'ssh-rsa AAAAB3NzaC1yc2EAAAA[...]=='
  user :dan, 'ssh-rsa AAAAB3NzaC1yc2EAAAA[...]=='
end
```

## Example Server Manifest File

The below file is an example of a `servers.km` file.

```ruby
# An example configuration for a server where all admin users have
# access as 'root' and all staff users have access as 'app'.
server do
  host 'app01.myapplication.com'
  user 'root', :admins
  user 'app', :admins, :staff
end

# An example configuration for a server where admins plus one other user
# have access as root only.
server do
  host 'database01.myapplication.com'
  user 'root', :admins, :dan
end

# An example of a group of servers each with the same permissions. These 
# will create servers with the same 
server_group :load_balancers do
  host 'lb01.myapplication.com'
  host 'lb02.myapplication.com'
  host 'lb03.myapplication.com'
  user 'root', :admins
  user 'app', :admins, :staff
end
```

You may add as many `.km` files as you wish to to your manifest directory and they
will be loaded. However, all **users** should be defined in `users.km` and nowhere 
else.

## Pushing files to servers

In order to push your authorized_keys files to your servers, keyman must be able
to authenticate. In the first instance, we will attempt to use your local SSH keys
to do this. If we cannot authenticate with these, you will be prompted for the password
when you attempt to push. This password, if accepted, will then be cached for your
"session" and attempted for any subsequent servers which cannot be authenticated with
your SSH keys.

```bash
$ cd path/to/manifest
# to push configuration to all servers
$ keyman push
# to push configuration to a specific server
$ keyman push database01.myapplication.com
# to push configuration to a server group
$ keyman push load_balancers
```

There are other commands available within the app, you can view these by 
viewing the inline help.

```bash
$ keyman help
```

## Storing your manifest directory

It is recommended to store your manifest directory in a Git repository. Once in a 
repository, you will be required to ensure that your local branch is always the same
as your remote branch before you can push to a server. This ensures that you cannot
overwrite someone elses changes should you forget to pull before pushing. 

This behaviour is automatic and currently non-optional when there is a .git directory
in your manifest.
