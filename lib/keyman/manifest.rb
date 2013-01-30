module Keyman
  class Manifest
    
    # Loads a manifest directory as live
    def self.load(directory = Keyman.manifest_dir)
      Keyman.users          = []
      Keyman.groups         = []
      Keyman.servers        = []
      Keyman.server_groups  = []
      manifest       = self.new(directory)
      if File.directory?(directory)
        [File.join(directory, 'users.km'), Dir[File.join(directory, '*.km')]].flatten.uniq.compact.each do |file|
          path = File.join(directory, file)
          if File.exist?(path)
            manifest.instance_eval(File.read(path))
          else
            raise Error, "No '#{file}' was found in your manifest directory. Abandoning..."
          end
        end
        Keyman.manifest = manifest
      else
        raise Error, "No folder found at '#{directory}'"
      end
    end
    
    # Initialize a new manifest with the current directory
    def initialize(directory)
      @directory = directory
    end
    
    # Adds a new group
    def group(name, &users_block)
      Group.add(name, &users_block)
    end
    
    # Adds a new server
    def server(&block)
      Server.add(&block)
    end
    
    # Adds a new user
    def user(username, key)
      User.add(username, key)
    end
    
    # Adds a new server group
    def server_group(name, &block)
      ServerGroup.add(name, &block)
    end
    
    # Does this manifest directory use git?
    def uses_git?
      File.directory?(File.join(@directory, '.git'))
    end
    
    # Is the current repo clean?
    def clean?
      `cd #{@directory} && git status`.chomp.include?('nothing to commit')
    end
    
    # Does the latest commit on the current branch match the remote brandh
    def latest_commit?
      local = `cd #{@directory} && git log --pretty=%H`.chomp
      if `cd #{@directory} && git status`.chomp.match(/On branch (.*)\n/)
        branch = $1
      else
        raise Error, "Unable to determine the local repository branch."
      end
      remote = `cd #{@directory} && git ls-remote 2> /dev/null | grep refs/heads/#{branch} `.chomp.split(/\s+/).first
      if local.length == 40 && remote.length == 40
        local == remote
      else
        raise Error, "Unable to determine local & remote commits"
      end
    end

  end
end
