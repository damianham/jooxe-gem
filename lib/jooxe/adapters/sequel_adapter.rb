require 'sequel'

module Jooxe
  class SequelAdapter
  
    def initialize table , klass     
      if table.respond_to?(:tablename)
        @table = table.tablename || table.name.demodulize.tableize
        
      elsif table.is_a?(String)
        @table = table
      else
        raise Exception "don't know how to instantiate table for #{table.class.name}"
      end
      @model_class = klass
    end
  
    # create a new record
    def create input
      table = DB.from(@table) #DB[@table]
    
      result = table.insert input

      input[:id] = result
    
      # invalidate a cached range
      @@_cached_range = nil
    
      # return an instance of the model class with the data attributes
      get :id => input[:id]
    end
  
    # save the given record
    def save input
      table = DB.from(@table) # DB[@table]
      
      # invalidate a cached range
      @@_cached_range = nil
      
      if input[:id]        
        table.where(:id => input[:id]).update input.reject{|key,value| key.to_s == 'id'}
        get :id => input[:id]
      else
        self.create input
      end   

    end

    # list records from the table optionally starting at a given offset (or page number)
    def list(options = nil)
      table = DB.from(@table)
      
      if options[:rows]
        if options[:offset]
          table = table.limit(options[:rows],options[:offset])
        elsif options[:page] 
          offset = options[:page] * options[:rows]
          table = table.limit(options[:rows],offset)
        end
      end
      
      # convert the array of hashes to an array of model objects
      table.all.map{|row| @model_class.new row}
    end
    
    def all
      table = DB.from(@table)
      # convert the array of hashes to an array of model objects
      table.all.map{|row| @model_class.new row}
    end
  
    # find a set of records matching the given options
    def find(options)
      table = DB.from(@table)
    
      options.each_pair do |method_name,params|
        table = table.send(method_name, params)
      end
    
      # convert the array of hashes to an array of model objects
      table.all.map{|row| @model_class.new row}
    end
  
    # get a specific instance from the table
    def get options
      table = DB.from(@table)
      result = table.first :id => options[:id]
      # return an instance of the model class with the data attributes
      @model_class.new result
    end

    # delete one or more records from the table
    def delete options
      table = DB.from(@table)
    
      if options[:where]
        result = table.where(options[:where]).delete
      else
        result = table.where(:id => options[:id]).delete
      end
    
      # invalidate a cached range
      @@_cached_range = nil
    
      return true if result == 1
      false
    end
    
    # get the set of tables in the database
    def self.tables
      @@cached_tables ||= DB.tables
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
      @cached_schema ||= DB.schema(@table)
    end
  
    # get the set of records from another class that are related to the
    # given instance giving the name of the related class
    # input => {:relation => "location", :id => 123}
    # if the record instance contains a 'location_id' field use that to
    # find the record the instance belongs to otherwise get the set of
    # records from the relation that have a foreign key matching the 
    # id of the instance
    # one to many, or many to one, or one to one relationship
    def related options
      
      belongs_to_field = options[:relation].to_s.foreign_key 
      table = DB.from(options[:relation].tableize)

      instance = get options
      
      if instance.has_key?(belongs_to_field)        
        result = table.where(:id => instance[belongs_to_field])
      else
        column_name = @table.singularize.foreign_key
        result = table.where(column_name => options[:id])
      end
      
      # convert the array of hashes to an array of model objects
      result.all.map{|row| @model_class.new row}
    end
  
    # get the set of records from another class that are related to the
    # given instance through a bridging class i.e. many to many relationship
    # User -> UserGroups -> Group
    # options => {:relation => "group", :id => 123, :through => 'user_group'}
    # Group.where(:id => UserGroup.select(:group_id).where(:user_id => 123))
    def bridged options
      table = DB.from(options[:relation].tableize)
      through = DB.from(options[:through].tableize)
      self_column_name = @table.singularize.foreign_key
      through_column_name = options[:relation].foreign_key
      
      result = table.where(:id => through.select(through_column_name).where(self_column_name => options[:id]))
      target_model_class = options[:relation].to_model_name
      # convert the array of hashes into objects of the target relation
      result.all.map{|row| target_model_class.new row}
    end
  
    # get an array of entries that each contain the table ID and a 
    # human readable identifier (a title or name)
    def range
      @cached_range ||= get_range
    end
  
    private
    
    def name_or_title item
      # if the current object has a method that returns the title column name
      if self.respond_to? :name_field && ! self.name_field.nil?
        # use the value from the name_field method as the hash key
        return item.send(name_field.to_sym) if item.respond_to? name_field.to_sym
      end
      
      return item.name if item.respond_to? :name
      return item.title if item.respond_to? :title
    end
    
    def get_range
      table = DB.from(@table)

      # get an array of arrays [id,'title']
      if @model_class.public_methods(false).include?(:to_range) 
        table.all.map{|item| item.to_range }.compact
      else
        table.all.map{|item| title = item[:name] || item[:title]
          title.nil? ? nil : [item[:id], title ]}.compact
      end
      
    end
    
    def method_missing(meth, *args, &block)
      table = DB.from(@table)
     
      # if the Sequel table responds to the method call it 
      if table.respond_to?(meth)
        table.send(meth, *args, &block)
      else
        super # You *must* call super if you don't handle the
        # method, otherwise you'll mess up Ruby's method
        # lookup.
      end
    end
    
  end

end
