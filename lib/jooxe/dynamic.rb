
module Jooxe
  
  class Loader
    
    # load the locally defined models
    def Loader.load_models(glob_pattern = 'app/models/*.rb')
      
      Dir.glob(glob_pattern) do |f|
        require f
      
        model_name = File.basename(f,'.rb')
        # define a controller for this model
        DynamicClassCreator.define_controller(model_name) 
      
      end
    end
    
    # load the locally defined controllers
    def Loader.load_controllers(glob_pattern = 'app/controllers/*.rb')
      
      Dir.glob(glob_pattern) do |f|
        require f
      end
    end
    
    # load the database column info
    def Loader.load_databases(glob_pattern = 'db/*.yml')
      
      $dbs = Hash.new if $dbs.nil?
    
      files = Dir.glob(glob_pattern)
      
      files.each do |yml_file|
      
        file_name = File.basename(yml_file,'.yml').split('_')[0]        
        
        db = YAML::load( File.open( yml_file ) )['schema']
        
        $dbs[file_name] = db
        
        # if only 1 db files exists then set it as the default - unless it is called default
        if files.size == 1 && file_name != 'default'
          $dbs['default'] = db
        end

      end
      
      # define a controller for every table
      $dbs.each do |database_name,tables|  
        tables.each_key do |key|  
          DynamicClassCreator.define_controller(key)   
          DynamicClassCreator.define_model(key,key) 
        end
         
      end
      
    end
    
  end
  
  class DynamicClassCreator
    
    def DynamicClassCreator.define_controller(name)
      class_name = name.to_controller_name
    
      Object.module_eval "class #{class_name} < ApplicationController; end" 
    end
    
    def DynamicClassCreator.define_model(name,table_name)
      class_name = name.to_model_name
        
      Object.module_eval "class #{class_name} < Jooxe::Model; end;"
      
    end
    
    
    def DynamicClassCreator.create_controller(env,name)
      
      self.define_controller(name)
      
      Object.module_eval "new_class = #{name.to_controller_name}.new"
 
    end
    
    def DynamicClassCreator.create_model(env,name,table_name)
      
      self.define_model(name,table_name)
      
      Object.module_eval "new_class = #{name.to_model_name}.new"

    end
    
  end
end