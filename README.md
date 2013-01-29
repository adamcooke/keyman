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
create an empty directory and add two files, a `servers.rb` and a `users.rb` file.

## Example Users/Groups Manifest File

The below file is an example of a `users.rb` manifest file.

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

The below file is an example of a `servers.rb` file.

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
```

## Pushing files to servers

In order to push files to the server, you must already have YOUR key on the
machine in order to authenticate. If you do not, you will not have access
and will therefore be unable to push configuration.

```bash
$ cd path/to/manifest
# to push configuration to all servers
$ keyman push
# to push configuration to a specific server
$ keyman push database01.myapplication.com
```

There are other commands available within the app, you can view these by 
viewing the inline help.

```ruby
$ keyman help
```
