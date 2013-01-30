module Keyman
  class User
    
    attr_accessor :name, :key
    
    # Add a new user with the given details
    def self.add(name, key)
      existing = Keyman.users.select { |u| u.name == name.to_sym }.first
      if existing
        existing
      else
        if existing = Keyman.user_or_group_for(name)
          raise Error, "#{existing.class.to_s.split('::').last} already exists for '#{name}' - cannot define user with this name."
        end
        
        u = self.new
        u.name = name.to_sym
        u.key = key
        Keyman.users << u
        u
      end
    end
    
  end
end
