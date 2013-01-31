require "jooxe/version"


module Jooxe
  class << self; attr_accessor :config; end
  
end

#load the config class
require 'jooxe/support/app_config'

Jooxe.config = Jooxe::AppConfig

#load the rest of the framework
require 'jooxe/framework'

module Jooxe
  
  class JooxeApplication
             
    def initialize
    
      @router = Jooxe::Router.new

      # load controllers and models
      Jooxe::Loader.load_models
    
      Jooxe::Loader.load_controllers 
  
      # load the database schema definitions
      Jooxe::Loader.load_databases
    
    end  
  
  
    def call(env)   
    
      req = Rack::Request.new(env)
    
      env[:request] = req
      env['JOOXE_ROOT'] = Dir.pwd
      
      # decode path into class,id,action
      options = @router.route(env)

      options[:layout] = 'application'
      env[:route_info] = options
      
      # if the router could not determine the controller class then display the 
      # homepage
      if options[:model_class_name].nil?
        # root URL
        
        view = Jooxe::View.new(env)
        return [200, {"Content-Type" => "text/html"}, Rack::Response.new(view.render_path('root'))]
      end
    
       
      begin 

        action = options[:action]

        params = options[:params]
        id = options[:id]
        @controller = options [:controller_class]
    
        view = @controller.send(action.to_sym)
        
        response = Rack::Response.new(view.render(options))
        [response.status, response.headers, response.body]
      end
 
    end
  
  
  end 

end
