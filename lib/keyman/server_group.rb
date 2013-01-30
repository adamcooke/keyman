module Keyman
  class ServerGroup
    
    attr_accessor :servers, :users, :name
    
    def initialize
      @servers = []
      @users = {}
    end
    
    def self.add(name, &block)
      s = self.new
      s.name = name
      s.instance_eval(&block)
      Keyman.server_groups << s
      s
    end
    
    def server(host, location = nil)
      @servers << Server.add_by_name(host, :users => @users, :group => self)
    end
    
    def user(name, *access_objects)
      @users[name] = access_objects
      @servers.each { |s| s.user(name, *access_objects) }
    end
    
  end
end
