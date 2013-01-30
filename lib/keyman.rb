require 'yaml'
require 'net/ssh'
require 'highline/import'

require 'keyman/user'
require 'keyman/group'
require 'keyman/server'
require 'keyman/server_group'
require 'keyman/manifest'

module Keyman
  
  # The current version of the keyman system
  VERSION = '1.1.0'
  
  # An error which will be raised
  class Error < StandardError; end
  
  class << self
    # Stores the actual manifest object
    attr_accessor :manifest
    
    # Storage for the manifest directory to work with
    attr_accessor :manifest_dir
    
    # Storage for all the users, groups & servers which are loaded
    # from the manifest
    attr_accessor :users
    attr_accessor :groups
    attr_accessor :servers
    attr_accessor :server_groups
    
    # Storage for a password cache to use within the current session
    attr_accessor :password_cache
    
    # Sets the default manifest_dir dir
    def manifest_dir
      @manifest_dir || self.config[:manifest_dir] || "./"
    end
    
    # Sets the configuration options
    def config
      @config ||= begin
        config_dir = File.join(ENV['HOME'], '.keyman')
        if File.exist?(config_dir)
          YAML.load_file(config_dir)
        else
          {}
        end
      end
    end

    # Return a user or a group for the given name
    def user_or_group_for(name)
      self.users.select { |u| u.name == name.to_sym }.first || self.groups.select { |u| u.name == name.to_sym }.first
    end
    
    # Execute a CLI command
    def run(args, options = {})
      Manifest.load
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
        
        if self.manifest.uses_git?
          unless self.manifest.clean?
            raise Error, "Your manifest is not clean. You should push to your repository before pushing."
          end
          
          unless self.manifest.latest_commit?
            raise Error, "The remote server has a more up-to-date manifest. Pull first."
          end
          
          puts "\e[32mRepository check passed!\e[0m"
        end
        
        if args[1]
          server = self.servers.select { |s| s.host == args[1] }.first
          server = self.server_groups.select { |s| s.name == args[1].to_sym }.first if server.nil?
          if server.is_a?(Keyman::Server)
            server.push!
          elsif server.is_a?(Keyman::ServerGroup)
            server.servers.each(&:push!)
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
        
      when 'status'
        if Keyman.manifest.uses_git?
          puts "Your manifest is using a remote git repository."
          if Keyman.manifest.clean?
            puts " * Your working copy is clean"
          else
            puts " * You have an un-clean working copy. You must commit before pushing."
          end
          
          if Keyman.manifest.latest_commit?
            puts " * You have the latest commit fetched."
          else
            puts " * There is a newer version of this repo on the server."
          end
        else
          puts "Your manifest does not use git. There is no status to display."
        end
        
      else
        raise Error, "Invalid command '#{args.first}'"
      end
    end
  end

end
