
module Jooxe
  
  #  decode path into [database]/class[/id][/action]
  # or with a nested path
  # decode path into [database]/class/id/class[/id][/action]


  class Router
 
    def initialize(glob_pattern = nil)
      # load database schema info using a given glob pattern 
      # allows us to load test database schemas
      Jooxe::Loader.load_databases glob_pattern unless glob_pattern.nil?
    end
    
    def route(env)
      path = env["PATH_INFO"]
    
      @env = env
    
      path_elements = path.split('/')
    
      while path_elements[0] == ''
        path_elements.shift
      end
    
      context = path_elements.dup
      
      @database_name = consume_context(path_elements)
      
      return {:root => true, :database_name => @database_name} if path_elements.length == 0
      
      # use the default database if no prefix given
      @database = $dbs[@database_name] || $dbs['default'] || {}
    
      @route_info = {:database => @database, :database_name => @database_name, :params => {}}
      
      while path_elements.length > 0
        
        # the next component should be a valid class name
        class_name = consume_class(path_elements)

        # get the current context which is all path elements up to the current class name
        @route_info[:context_prefix] = "/" + context[0,context.length - path_elements.length - 1].join('/')
        @route_info[:model_class_name] = class_name.to_model_name unless class_name.nil?
        @route_info[:controller_class] = @controller_class
        @route_info[:model_class] = @model_class
        @route_info[:column_info] = @column_info
        @route_info[:table_name] = @table_name

        # id and action may be nil
        id = consume_id(path_elements)

        action = consume_action(path_elements)

        if action.nil? 
          
          if id.nil?
            case env["REQUEST_METHOD"]
            when "POST"
              action = 'create'
            else
              action = 'index'
            end
          else
            case env["REQUEST_METHOD"]
            when "PUT"
              action = 'update'
            when "DELETE"
              action = 'destroy'
            else
              action = 'show'
            end
          end          

        end
      
        @route_info.update  :action => action  
        
        if ! id.nil?
          param_name = class_name.to_s.singularize+'_id'
           
          @route_info[:params].update  :id => id, param_name.to_sym => id  
               
        else
          @route_info[:params].delete(:id)
        end
        
      end
      
      @route_info
    
    end

    def consume_context(paths)
      if $dbs.has_key?(paths[0]) 
        paths.shift
      end
    end
  
    def consume_class(paths)
      return nil if paths[0].nil?
    
      # generate the controller name
      class_name =  paths[0].to_controller_name
      
      possible_table_names = [paths[0], paths[0].singularize, paths[0].pluralize]
      
      @table_name = possible_table_names.dup.reject { |name| ! @database.has_key?(name)}[0]
      
      if @table_name.nil?     
        raise NameError.new("Class not found #{class_name}")
      end
      
      @column_info = @database[@table_name]["columns"]
      
      begin 
        # assign the controller class 
        eval "@controller_class = #{class_name}.new"        
        @controller_class.env=@env.merge(:route_info => @route_info)
      rescue NameError => boom
        # loading the class failed so create the controller class dynamically
        @controller_class = Jooxe::DynamicClassCreator.create_controller(@env.merge(:route_info => @route_info),paths[0])
      end

      # assign the model
      class_name =  paths[0].to_model_name
      begin
        eval "@model_class = #{class_name}.new"
        @model_class.env = @env.merge(:route_info => @route_info)
      rescue NameError => boom
        # loading the class failed so create the model class dynamically
        @model_class = Jooxe::DynamicClassCreator.create_model(@env.merge(:route_info => @route_info),paths[0],@table_name)
      end
      
      #@model_class = @model_class.class
      
      return paths.shift
      
    end
  
    def consume_id(paths)
      return nil if paths[0].nil?
    
      # the result could be a numeric ID /^\d+$/

      return paths.shift if paths[0] =~ /^\d+$/
    
      # IDs generated by SecureRandom.urlsafe_base64 (rfc 3584) are usually 4/3 of 16 bytes or more
      # a UUID generated by SecureRandom.uuid  is a v4 Random UUID (rfc 4112) 5 groups of chars 8-4-4-4-12
    
      return nil unless paths[0].length > 16
    
      # if there is any number in the path element then it is an ID
      if paths[0] =~ /\d/
        return paths.shift
      end
    end
  
    def consume_action(paths)
      return nil if paths[0].nil?
    
      # if the element is a known class we cannot consider it an action
      return nil if @database.has_key?(paths[0])

      # if the path element is the last element in the path check 
      # a method of the same name can be performed on the current controller class
      if paths.length ==1
        if ! @controller_class.nil? && @controller_class.respond_to?(paths[0].to_sym)
          return paths.shift
        end 
      end
   
    end
  
  end

end