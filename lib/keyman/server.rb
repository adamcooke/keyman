module Keyman
  class Server
    
    attr_accessor :host, :users, :location, :group
    
    def initialize
      @users = {}
    end
    
    # Adds a new server by accepting a block of objects
    def self.add(&block)
      s = self.new
      s.instance_eval(&block)
      Keyman.servers << s
      s
    end
    
    # Adds a new server based on it's name and location
    def self.add_by_name(host, options = {})
      s = self.new
      s.host = host
      s.location = options[:location]
      s.users = options[:users]
      s.group = options[:group]
      Keyman.servers << s
      s
    end
    
    # Returns or sets the hostname of the server which should be used when connecting
    # and identifying this server
    def host(host = nil)
      host ? @host = host : @host
    end
    
    # Sets a user on the server along with the access objects which should be
    # granted access
    def user(name, *access_objects)
      access_objects.each { |ao| raise Error, "!! Invalid access object '#{ao}' on '#{self.host}'" unless Keyman.user_or_group_for(ao) }
      @users[name] = access_objects
    end
    
    # Returns or sets the location of the server
    def location(location = nil)
      location ? @location = location : @location
    end
    
    # Returns an array of users who have access to this server. Includes
    # all objects from within the server
    def authorized_users(username)
      @users[username].map do |k|
        if obj = Keyman.user_or_group_for(k)
          obj.is_a?(Group) ? obj.users : obj
        else
          nil
        end
      end.flatten.compact.uniq
    end
    
    # Returns a full string output for the authorized_keys file. Passes
    # the user who's file you wish to generate.
    def authorized_keys(username)
      Array.new.tap do |a|
        a << "# SSH Authorized Keys file generated automatically by Keyman"
        a << "# Generated at: #{Time.now.utc} for #{@host}"
        a << nil
        authorized_users(username).each do |u|
          a << "# #{u.name}"
          a << u.key + "\n"
        end
      end.join("\n")
    end
    
    # Push the authorized keys file to the appropriate server for the users
    # configured here. This will not succeed if the current user does not
    # already have a key on the server.
    def push!
      passwords_to_try = (Keyman.password_cache ||= [nil]).dup
      @users.each do |user, objects|
        begin
          passwords_to_try.each do |password|
            Timeout.timeout(10) do |t|
              Net::SSH.start(self.host, user, :password => password) do |ssh|
                ssh.exec!("mkdir -p ~/.ssh")
                file = authorized_keys(user).gsub("\n", "\\n").gsub("\t", "\\t")
                ssh.exec!("echo -e '#{file}' > ~/.ssh/authorized_keys")
              end
              Keyman.password_cache << password if password
            end
          end
          puts "\e[32mPushed authorized_keys to #{user}@#{self.host}\e[0m"
        rescue Net::SSH::AuthenticationFailed
          passwords_to_try.shift
          if passwords_to_try.empty?
            puts "\e[35mAuthorization failed on to #{user}@#{self.host}.\e[0m"
            password = HighLine.ask("Enter password: ") { |q| q.echo = "*" }
            if password.length > 0
              passwords_to_try << password
              retry
            else
              puts "\e[37mSkipping #{user}@#{self.host}\e[0m"
            end
          else
            retry
          end
        rescue Timeout::Error
          puts "\e[31mTimed out while uploading authorized_keys to #{user}@#{self.host}\e[0m"
        rescue => e
          puts "\e[31mFailed to upload authorized_keys to #{user}@#{self.host} (#{e.class})\e[0m"
          puts e.message
        end
      end
    end
    
  end
end
