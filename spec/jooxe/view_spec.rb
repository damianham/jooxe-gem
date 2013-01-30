require 'spec_helper'

module Jooxe
  
  describe View do
    
    before(:all) do
      $dbs = nil
      Jooxe::Loader.load_databases 'test/db/*.yml'
      
      @env = { # setup some basic values in the env hash

      "GATEWAY_INTERFACE" => "CGI/1.1",
      "PATH_INFO" => "/helios/users",
      "REMOTE_ADDR" => "0:0:0:0:0:0:0:1",
      "REMOTE_HOST" => "0:0:0:0:0:0:0:1",
      "REQUEST_METHOD" => "GET",
      "JOOXE_ROOT" => ENV['JOOXE_ROOT'],
      "SCRIPT_NAME" => "",
      "SERVER_NAME" => "localhost",
      "SERVER_PORT" => "9292",
      "SERVER_PROTOCOL" => "HTTP/1.1",
      "SERVER_SOFTWARE" => "WEBrick/1.3.1 (Ruby/1.9.2/2012-05-01)",
      "HTTP_HOST" => "localhost:9292",
      "HTTP_CONNECTION" => "keep-alive",
      "HTTP_CACHE_CONTROL" => "max-age=0",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11",
      "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_ACCEPT_ENCODING" => "gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.8",
      "HTTP_ACCEPT_CHARSET" => "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
      "HTTP_RANGE" => "bytes=1458-1458",
      "HTTP_IF_RANGE" => "\"7406a4673c6917a581f234009cd95028\"",
      "rack.version" => [1, 1],
      #rack.input == #>,
      #rack.errors == #>,
      "rack.multithread" => false,
      "rack.multiprocess" => false,
      "rack.run_once" => false,
      "rack.url_scheme" => "http",
      "HTTP_VERSION" => "HTTP/1.1",
      "jooxe.request_id" => "13f37d89-90e6-4980-b805-4438737a2e75"}

    end
    
    before(:each) do
      
      @router = Router.new 
      
      req = Rack::Request.new(@env)
      @env[:request] = req
    end
    
    # instance
    it "should return an instance" do
      ss = "this is a string"
      options = {:instance => ss}
      view = Jooxe::View.new(@env,self,options)
      view.instance.should eq(ss)
      view.collection.should eq(nil)
    end
    
    # collection
    it "should return a collection" do
      aa = ['a','b','c']
      options = {:collection => aa}
      view = Jooxe::View.new(@env,self,options)
      view.collection.should eq(aa)
      view.instance.should eq(nil)
    end
    
    it "should redirect to a URI" do
      ss = "/users/index"
      options = {:redirect_to => ss}
      view = Jooxe::View.new(@env,self,options)
      view.redirect_to.should eq(ss)
      view.instance.should eq(nil)
      view.collection.should eq(nil)
    end
    
    
    # render_path with layout
    it "should render a template from a given path with layout" do
      options = {:layout => 'render_path'}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render_path 'render_path_test'
      output.should be_an_instance_of(String)
      output.should match(/render_path.html layout/)
      output.should match(/render_path_test/)
    end
    
    # render_path without layout
    it "should render a template from a given path without layout" do
      options = {:layout => nil}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render_path 'render_path_test'
      output.should be_an_instance_of(String)
      #output.should match(/render_path.html layout/)
      output.should match(/render_path_test/)
    end
    
    # render partial without layout in the model's views folder
    it "should render a partial template relative to the model" do
       options = {:layout => nil, :model_class_name => 'User', :partial => 'render_partial_user'}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      #output.should match(/render_path.html layout/)
      output.should match(/render_partial_user/)
    end
    
    # render partial without layout in the shared partials folder
    it "should render a shared partial template " do
      options = {:layout => nil, :partial => '/partials/render_partial_test'}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      #output.should match(/render_path.html layout/)
      output.should match(/render_partial_test/)
    end
   
    # render embedded partial with layout
    it "should render an embedded partial template relative to the model" do
       options = {:layout => 'render_partial',:model_class_name => 'User', :partial => 'render_local_partial'}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/render_partial.html layout/)  # layout
      output.should match(/render_local_partial.html/) # first partial
      output.should match(/render_embedded_partial_user.html/) # embedded partial
      
    end
    
    # render embedded shared partial with layout
    it "should render an embedded shared partial template" do
       options = {:layout => 'render_partial',:model_class_name => 'User', :partial => 'render_shared_partial'}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/render_partial.html layout/) # layout
      output.should match(/render_shared_partial.html/) # first partial
      output.should match(/render_embedded_shared.html/) # embedded partial
    end
    
    # render with instance variables
    it "should render with instance variables" do
      options = {:layout => 'render_partial',:model_class_name => 'User', :partial => 'render_instance_variables'}
      @context_variable = "this is the context variable"
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/render_partial.html layout/)  # layout
      output.should match(/render_instance_variables.html/)  # partial
      output.should match(/this is the context variable/) # context variable
    end
    
    # render with passed variables
    it "should render with passed local variables" do
      local_variable = "this is the local variable"
      options = {:layout => 'render_partial',
        :model_class_name => 'User', 
        :partial => 'render_local_variables',
        :locals => {:local_variable => local_variable}
        }
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/render_partial.html layout/)  # layout
      output.should match(/render_local_variables.html/)  # partial
      output.should match(/this is the local variable/) # context variable
    end
    
   
    # render show action with layout
    it "should render an instance with class template in layout" do
      user = User.new :id => 123,:account_name => 'jim',
  :title => 'Mr', 
  :given_name => 'john',
  :surname => 'ldfkjsld',
  :country => 'GB',
  :mail => 'john@example.com',
  :updated_at => '2012-12-21 23:59:59',
  :updated_by => 'admin'  

       options = {:layout => 'application', :model_class_name => 'User',
         :action => 'show', :instance => user}
      
      # set the instance variable before creating the view so the variable
      # is copied into the context of the view
      @instance = user
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(@instance)
      view.collection.should eq(nil)
            
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/application.html layout/)  # layout
      output.should match(/show.html action template/) # instance template
      output.should match(/ldfkjsld/)  # instance data
    end

  
    # render show action with layout
    it "should render an instance with generic template in layout" do
      user = User.new :id => 123,:account_name => 'jim',
  :title => 'Mr', 
  :given_name => 'john',
  :surname => 'ldfkjsld',
  :country => 'GB',
  :mail => 'john@example.com',
  :updated_at => '2012-12-21 23:59:59',
  :updated_by => 'admin'  

       options = {:layout => 'application', :model_class_name => 'User',
         :action => 'other', :instance => user}
      
      # set the instance variable before creating the view so the variable
      # is copied into the context of the view
      @instance = user
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(@instance)
      view.collection.should eq(nil)
            
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/application.html layout/)  # layout
      output.should match(/instance.html generic template/) # instance template
      output.should match(/ldfkjsld/)  # instance data
    end
      
    # render list action with layout
    it "should render a collection with class template in layout" do
      
      users = Jooxe::User.list
      
       options = {:layout => 'application', :model_class_name => 'User',
         :action => 'list', :collection => users}
      
      # set the collection variable before creating the view so the variable
      # is copied into the context of the view
      @collection = users
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(@collection)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/application.html layout/)  # layout
      output.should match(/list.html  action template/) # list action template
      output.should match(/ldfkjsld/)  # instance data
    end

    # render list action with layout
    it "should render a collection with generic template in layout" do
      
      posts = Jooxe::Post.list
      
       options = {:layout => 'application', :model_class_name => 'Post',
         :action => 'list', :collection => posts}
      
      # set the collection variable before creating the view so the variable
      # is copied into the context of the view
      @collection = posts
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(@collection)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/application.html layout/)  # layout
      output.should match(/collection.html generic template/) # generic collection template
      output.should match(/this is the title of post 1/)  # instance data
    end
    
    
    # render as json without layout
    it "should render an instance in json without layout" do
      
      user = User.new :id => 123,:account_name => 'jim',
  :title => 'Mr', 
  :given_name => 'john',
  :surname => 'ldfkjsld',
  :country => 'GB',
  :mail => 'john@example.com',
  :updated_at => '2012-12-21 23:59:59',
  :updated_by => 'admin'  

      
      #puts "json == " + user.inspect
      
       options = {:layout => nil, :json => user}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      #output.should match(/render_path.html layout/)
      output.should match(/"surname":"ldfkjsld"/)
    end
    
    # render as json without layout
    it "should render a collection in json without layout" do
      
      posts = Jooxe::Post.list
      
       options = {:layout => nil, :json => posts}
      
      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      #output.should match(/render_path.html layout/)
      output.should match(/"title":"this is the title of post 2"/)
    end   
    
    it "should call a helper method" do
      options = {:layout => 'render_partial',:model_class_name => 'User', :partial => 'call_helper_method'}

      view = Jooxe::View.new(@env,self,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/render_partial.html layout/)  # layout
      output.should match(/call_helper_method.html/)  # partial
      output.should match(%r{/user/123/edit}) # helper method
    end
    
    it "should call a method in the calling context" do
      options = {:layout => 'render_partial',:model_class_name => 'User', :partial => 'call_context_method'}

      class TestContext
        def context_method
          "this is the result from the context method"
        end
      end
      
      view = Jooxe::View.new(@env,TestContext.new,options)
      
      view.instance.should eq(nil)
      view.collection.should eq(nil)
      
      output = view.render options
      output.should be_an_instance_of(String)
      output.should match(/render_partial.html layout/)  # layout
      output.should match(/call_context_method.html/)  # partial
      output.should match(/this is the result from the context method/) # context method
    end
    
  end
  
  
  
end
