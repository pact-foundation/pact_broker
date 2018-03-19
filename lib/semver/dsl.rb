module XSemVer
  
  module DSL
    
    def self.included(klass)
      klass.extend ClassMethods
      klass.send :include, InstanceMethods
    end

    class CommandError < StandardError
    end    
    
    
    
    
    module InstanceMethods
      
      # Calls an instance method defined via the ::command class method.
      # Raises CommandError if the command does not exist.
      def run_command(command)
        method_name = "#{self.class.command_prefix}#{command}"
        if self.class.method_defined?(method_name)
          send method_name
        else
          raise CommandError, "invalid command #{command}"
        end
      end
      
    end




    module ClassMethods
      
      # Defines an instance method based on the first command name.
      # The method executes the code of the given block.
      # Aliases methods for any subsequent command names.
      def command(*command_names, &block)
        method_name = "#{command_prefix}#{command_names.shift}"
        define_method method_name, &block
        command_names.each do |c|
          alias_method "#{command_prefix}#{c}", method_name
        end
      end
      
      # The prefix for any instance method defined by the ::command method.
      def command_prefix
        :_run_
      end
      
    end




  end
  
end