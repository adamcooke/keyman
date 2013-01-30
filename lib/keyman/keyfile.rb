module Keyman
  class Keyfile
    
    class << self
      def group(name, &users_block)
        Group.add(name, &users_block)
      end
      
      def server(&block)
        Server.add(&block)
      end
      
      def user(username, key)
        User.add(username, key)
      end
      
      def server_group(name, &block)
        ServerGroup.add(name, &block)
      end
    end
    
  end
end
