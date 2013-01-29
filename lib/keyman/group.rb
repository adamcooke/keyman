module Keyman
  class Group
    
    attr_accessor :name, :users
    
    def initialize
      @users = []
    end
    
    # Add a new group with the given name
    def self.add(name, &block)
      g = Group.new
      g.name = name
      g.instance_eval(&block)
      Keyman.groups << g
    end
    
    # Add a new user to the group
    def user(*args)
      @users << User.add(*args)
    end
    
  end
end
