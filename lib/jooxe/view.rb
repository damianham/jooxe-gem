
require 'erubis'
require 'tilt'
require 'json/add/core' # load a set of common additions to ruby core's objects
require 'erb'

module Jooxe
  class View

    # include the path helper
    include Jooxe::Path
    include ERB::Util
    
    attr_accessor :context, :env, :content
    
    def initialize(env,binding_context = nil,options = {})
      @env = env
      @context = binding_context  # the controller that performed the action
      @options = options
      
      # set the instance variables from the context into the local scope so they
      # can be referenced from templates when self is the binding context
      @context.instance_variables.each do |name|
        self.instance_variable_set(name, @context.instance_variable_get(name))
      end
      @content = {}
    end
    
    # render a template from a given filename using one of the request formats
    # the file should exist in either @env['JOOXE_ROOT']/app/views 
    # or @env['JOOXE_ROOT']/app/templates.  
    def render_path(filename)
      
      template_file = nil
      # try each requested format in turn until we find a view or template
      requested_formats.each { |format|
        
        # unless we have already found a requested template type
        if template_file.nil? 
          path = File.join(@env['JOOXE_ROOT'],"app","views","#{filename}.#{format}.*")
          
          files = Dir.glob(path)
          
          template_file = files[0]
          
          if template_file.nil? 
            path = File.join(@env['JOOXE_ROOT'],"app","templates", "#{filename}.#{format}.*")
            files = Dir.glob(path)
            template_file = files[0]            
          end
        
        end
      }
      render_template(template_file,@options)
    end
    
    def render(options = @options)
      
      
      if @current_template_folder.nil?
        if options[:model_class_name]
          @current_template_folder = File.join(@env['JOOXE_ROOT'],"app","views",options[:model_class_name].downcase)
        else
          @current_template_folder = File.join(@env['JOOXE_ROOT'],"app","views")
        end
      end

      if options.has_key?(:json)
        return JSON.generate(options[:json])
      end
            
      if options.has_key?(:partial)
        template_file = resolve_partial options
      else
        template_file = template_for_requested_format options
      end

      render_template(template_file,options)
    end
    
    def redirect_to
      @options[:redirect_to]
    end
    
    def collection
      @options[:collection]
    end
    
    def instance
      @options[:instance]
    end
    
    def action
      @options[:action]
    end
    
    private
    
    def requested_formats
      
      # ensure the accept env variable has a value
      @env["HTTP_ACCEPT"] = "text/html" if @env["HTTP_ACCEPT"].nil?
      
      # e.g "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      # get the requested formats from HTTP_ACCEPT
      formats = @env["HTTP_ACCEPT"].split(',').map { |x| 
        case x
        when /html$/
          'html'
        when /xml$/
          'xml'
        when /json$/
          'json'
        else
          nil
        end
      }.compact
      
      @preferred_format = formats[0]
      formats
    end
    
    def render_template_raw(template_file,options = {})
      @current_template_folder = File.dirname(template_file)
      template = Tilt.new(template_file)
      template.render(self, options[:locals])
    end
    
    # render the given template 
    def render_template(template_file,options = {})
           
      # if no layout is specified in the options then get the layout
      # from the binding context
      if options.has_key?(:layout)
        layout = options[:layout]
      elsif @content.respond_to?(:layout)
        layout = @context.layout
      end

      if layout.nil? || @preferred_format == 'json'
        # render the template without a layout
        render_template_raw(template_file,options)
      else
        # uhmmm render with a layout
        render_template_with_layout(layout,template_file,options)
      end
    end
    
    def get_layout_template filename
      template_file = nil
      # try each requested format in turn until we find a view or template
      requested_formats.each { |format|
        
        # unless we have already found a requested template type
        if template_file.nil? 
          path = File.join(@env['JOOXE_ROOT'],"app","views","layouts",  "#{filename}.#{format}.*")
          
          files = Dir.glob(path)
          
          template_file = files[0]
        
        end
      }
      template_file
    end
    
    def render_template_with_layout(layout,template_file,options = {})
      layout_file = get_layout_template(layout)
      
      template = Tilt.new(layout_file)
      template.render( self, options[:locals]) { |sym|
        
        @content[:layout] ||= render_template_raw(template_file,options)
        
        if sym.nil? || sym == :layout
          content = @content[:layout]
        else
          content = @content[sym]
        end
        content
      }
    end
    
    def glob_paths(format,options = {})
      # add a path that expands to the object class name and an action i.e. app/views/users/show.html.erb
      paths = [File.join(@env['JOOXE_ROOT'],"app","views", options[:model_class_name].downcase,"#{options[:action].downcase}.#{format}.*")]
      
      if ["new","edit"].include?(options[:action].downcase)
        # add paths that expands to any form template with the object class name 
        # i.e. app/views/users/form.html.erb or app/templates/forms/user.html.erb
        paths << File.join(@env['JOOXE_ROOT'],"app","views", options[:model_class_name].downcase,"form.#{format}.*")
        paths << File.join(@env['JOOXE_ROOT'],"app", "forms","#{options[:model_class_name].downcase}.#{format}.*")
      else
        # add a path that expands to any template with the object class name i.e. app/templates/tables/user.html.erb
        paths << File.join(@env['JOOXE_ROOT'],"app","templates", "**","#{options[:model_class_name].downcase}.#{format}.*")
      end
      paths
    end
    
    def resolve_partial(options = {})
      template_file = nil
      
      partial = options[:partial]
      
      if partial[0] == '/'
        relative_root = File.join(@env['JOOXE_ROOT'],"app","views")
      else
        relative_root = @current_template_folder
      end
      
      requested_formats.each { |format|
        # unless we have already found a requested partial
        if template_file.nil? 
          files = File.join(relative_root,  "#{partial}.#{format}.*")

          template_file = Dir.glob(files)[0]       
        end
        
        
      }
      raise "partial template #{partial} not found" unless template_file
      template_file
    end

    def template_for_requested_format(options = {})
      
      template_file = nil
      
      # try each requested format in turn until we find a view or template
      requested_formats.each { |format|
        
        glob_paths(format,options).each do |path|
          # unless we have already found a requested template type
          
          if template_file.nil? 
            template_file = Dir.glob(path)[0]  
          end   
          
        end

      }
      
      # use the generic collection or instance template
      if template_file.nil?
        requested_formats.each { |format|
          template_type = @options[:collection].nil? ? 'instance' : 'collection'
          # unless we have already found a requested template type
          if template_file.nil? 
            files = File.join(@env['JOOXE_ROOT'],"app","templates", "generic",  "#{template_type}.#{format}.*")

            template_file = Dir.glob(files)[0]       
          end
        }
      end
      raise "template for #{options[:model_class_name].downcase}::#{options[:action].downcase} not found" unless template_file
      template_file
    end
    
    def content_for sym, &block
      @content[sym] = block.call
    end
    
    def method_missing(meth, *args, &block)
      
     
      # the method name is not a known attribute 
      if @context.respond_to?(meth)
        @context.send(meth, *args, &block)
      else
        super # You *must* call super if you don't handle the
        # method, otherwise you'll mess up Ruby's method
        # lookup.
      end
    end
    
  end
end