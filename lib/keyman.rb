require 'net/ssh'

require 'keyman/user'
require 'keyman/group'
require 'keyman/server'
require 'keyman/server_group'
require 'keyman/keyfile'

module Keyman
  
  # The current version of the keyman system
  VERSION = '1.1.0'
  
  # An error which will be raised
  class Error < StandardError; end
  
  class << self
    # Storage for all the users, groups & servers which are loaded
    # from the manifest
    attr_accessor :users
    attr_accessor :groups
    attr_accessor :servers
    attr_accessor :server_groups

    # Load a manifest from the given folder
    def load(directory)
      self.users          = []
      self.groups         = []
      self.servers        = []
      self.server_groups  = []
      if File.directory?(directory)
        ['./users.km', Dir[File.join(directory, '*.km')]].flatten.uniq.each do |file|
          puts file
          path = File.join(directory, file)
          if File.exist?(path)
            Keyman::Keyfile.class_eval(File.read(path)) 
          else
            raise Error, "No '#{file}' was found in your manifest directory. Abandoning..."
          end
        end
      else
        raise Error, "No folder found at '#{directory}'"
      end
    end
    
    # Return a user or a group for the given name
    def user_or_group_for(name)
      self.users.select { |u| u.name == name.to_sym }.first || self.groups.select { |u| u.name == name.to_sym }.first
    end
    
    # Execute a CLI command
    def run(args, options = {})
      load('./')
      case args.first
      when 'keys'
        if server = self.servers.select { |s| s.host == args[1] }.first
          if server.users[args[2]]
            puts server.authorized_keys(args[2])
          else
            raise Error, "'#{args[2]}' is not a valid user for this host"
          end
        else
          raise Error, "No server found with the hostname '#{args[1]}'"
        end
      when 'permissions'
        if server = self.servers.select { |s| s.host == args[1] }.first
          server.users.each do |username, objects|
            puts '-' * 80
            puts "\e[32m#{username}\e[0m can be used by:"
            puts '-' * 80
            server.authorized_users(username).each do |o|
              puts " * #{o.name}"
            end
          end
        else
          raise Error, "No server found with the hostname '#{args[1]}'"
        end
      when 'push'
        if args[1]
          # push single server
          if server = self.servers.select { |s| s.host == args[1] }.first
            server.push!
          else
            raise Error, "No server found with the hostname '#{args[1]}'"
          end
        else
          self.servers.each(&:push!)
        end
      when 'servers'
        self.server_groups.sort_by(&:name).each do |group|
          puts '-' * 80
          puts group.name.to_s
          puts '-' * 80
          group.servers.each do |s|
            puts " * #{s.host}"
          end
        end
        
        puts '-' * 80
        puts 'no group'
        puts '-' * 80
        self.servers.select { |s| s.group.nil?}.each do |s|
          puts " * #{s.host}"
        end
        
      when 'users'
        self.groups.each do |group|
          puts "-" * 80
          puts group.name
          puts "-" * 80
          group.users.each do |u|
            puts "\e[32m#{u.name}\e[0m"
            puts "\e[37m#{u.key}\e[0m"
          end
        end
      end
    end
  end

end
