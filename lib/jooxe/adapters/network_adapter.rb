require 'json'

# a class to access data via a remote web service
# JSON is used for data transport
module Jooxe
  
  class NetworkAdapter
  
    # initialize with an endpoint that is setup with the web service url
    def initialize endpoint, klass
      if endpoint.respond_to?(:endpoint)  && endpoint.respond_to?(:tablename)
        tablename = endpoint.tablename || endpoint.name.demodulize.tableize
        @endpoint = NetworkEndpoint.new endpoint.endpoint + '/' + tablename
      elsif endpoint.is_a?(String)
        @endpoint = endpoint
      else
        raise Exception "don't know how to instantiate endpoint for #{endpoint.class.name}"
      end
      @model_class = klass
    end
  
    # create a new record
    def create input
    
      # invalidate a cached range
      @@_cached_range = nil
      result = @endpoint.insert input
      
      @model_class.new result
    end
  
    # save the given record
    def save input
    
      # invalidate a cached range
      @@_cached_range = nil
      
      if input[:id]
        @endpoint.update input
        
        # return an instance of the model class with the data attributes
        get input
      else
        input = self.create input
      end
      
    end

    # list records from the web service 
    def list(options = nil)
      result = @endpoint.list options
      
      # convert the array of hashes to an array of model objects
      result.all.map{|row| @model_class.new row}
    end
    
     # get all records from the web service 
    def all
      result = @endpoint.all
      
      # convert the array of hashes to an array of model objects
      result.all.map{|row| @model_class.new row}
    end
  
    # find a set of records matching the given options
    def find(options)
      result = @endpoint.find options
      
      # convert the array of hashes to an array of model objects
      result.all.map{|row| @model_class.new row}
    end
  
    # get a specific instance from the webservice
    def get options
      result = @endpoint.get options
      
      # return an instance of the model class with the data attributes
      @model_class.new result
    end

    # delete one or more records from the table
    def delete options
      result = @endpoint.delete options
    
      # invalidate a cached range
      @@_cached_range = nil
    
      return true if result == 1
      false
    end
  
    # get the set of tables in the database
    def self.tables
      @@cached_tables ||= @endpoint.tables
    end
    
    # get the set of columns in the table
    # Returns the schema for the given table as an array with all members 
    # being arrays of length 2, the first member being the column name, 
    # and the second member being a hash of column information.
    # [[:id,
#   {:type=>:integer,
#    :primary_key=>true,
#    :default=>"nextval('artist_id_seq'::regclass)",
#    :ruby_default=>nil,
#    :db_type=>"integer",
#    :allow_null=>false}],
#  [:name,
#   {:type=>:string,
#    :primary_key=>false,
#    :default=>nil,
#    :ruby_default=>nil,
#    :db_type=>"text",
#    :allow_null=>false}]]
    def schema
      @cached_schema ||= @endpoint.schema
    end
  
    # get the set of records from another class that are related to the
    # given instance
    # one to many, or many to one, or one to one relationship
    def related options
      result = @endpoint.related options
      
      # convert the array of hashes to an array of model objects
      result.all.map{|row| @model_class.new row}
    end
  
    # get the set of records from another class that are related to the
    # given instance through a bridging class i.e. many to many relationship
    # User -> UserGroups -> Group
    # options => {:relation => "group", :id => 123, :through => 'user_group'}
    # Group.where(:id => UserGroup.select(:group_id).where(:user_id => 123))
    def bridged options
      result = @endpoint.bridged options
      
      target_model_class = options[:relation].to_model_name
      # convert the array of hashes into objects of the target relation
      result.all.map{|row| target_model_class.new row}
    end
  
    # get an array of entries that each contain the table ID and a 
    # human readable identifier (a title or name)
    def range options
      @cached_range ||= @endpoint.range options
    end
  
  end

end