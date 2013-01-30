module Jooxe
  
  class AppConfig

    class << self

      attr_accessor :values

    end

    @values = {}
    
    def self.define_setter(attr_name)
      
      # define a dynamic setter which sets the attr_name value to the value given on invocation
      class_eval <<-RUBY
      def self.#{attr_name}=(value)        
        @values[attr_name] = value  
      end                           
      RUBY
    end
    
    def self.define_getter(attr_name)
      self.class.send :define_method, attr_name do
        @values[attr_name] || @values[attr_name.to_s]
      end
    end

    def self.method_missing(sym, *args, &block)
      
      # if the method name is a setter then define a setter
      # and return the set value
      if sym.to_s =~ /^(.+)=$/
        define_setter($1)
        return @values.update($1 => args[0])
      end
      
      # define a getter if the key exists
      if @values.has_key?(sym.to_s) 
        define_getter(sym)
      end
      
      # return any value or nil
      @values[sym.to_s]

    end

    def self.reset_configs

      self.values = {}
      
      values = ApplicationConfig.all

      values.each do |setting|

        self.values = {setting.config_key => setting.config_value}.merge self.values

      end

    end

  end

end
