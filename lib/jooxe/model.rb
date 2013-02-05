require 'sequel'
require 'json'

module Jooxe
  
  # base class for all models
  class Model 
    
    # the default adapter type
    @adapter_type = :sequel
    
    extend Jooxe::Adapter
    
    class << self
      attr_accessor :tablename
      attr_accessor :adapter_type
      attr_accessor :column_schema  
      attr_accessor :adapter
      attr_accessor :fields
    end
    
    attr_writer :env
    attr_writer :values
    
    def self.inherited(subclass)
      subclass.tablename = subclass.name.demodulize.tableize
      subclass.adapter = adapter_for_class(subclass)
      subclass.fields = {}
    end
    
    def initialize values = nil
      @values = values || {}
    end
    
    def adapter
      self.class.adapter
    end
    
    def to_param
      if self.id.nil?
        nil
      else
        self.id.to_s
      end
    end
    
    def to_json(*a)
      @values.to_json(*a)
    end
    
    def self.list options = {}
      adapter.list options
    end
    
    def self.all
      adapter.all
    end
    
    def self.find options
      adapter.find options
    end
    
    def self.get options
      adapter.get options
    end
    
    def self.create options 
      adapter.create options
    end
    
    def list options = {}
      self.class.list options
    end
    
    def all
      self.class.all
    end
    
    def get options
      self.class.get options
    end
    
    def create options 
      self.class.create options
    end
    
    def update input
      # update the timestamp if this class has an updated_at column
      if is_a_known_attribute?(:updated_at)
        input.update(:updated_at => Time.now)
      end
      adapter.save input.merge(:id => self.to_param)
    end
    
    def self.delete options
      adapter.delete options
    end
    
    def delete options = {}
      self.class.delete options.merge(:id => self.to_param)
    end
    
    def self.schema
      
      @table_schema ||= lambda { |table|
 
        # if the database schema has been generated then use that
        if $dbs.has_key?('default')
          database = $dbs['default']

          if database.has_key?(table)
            return database[table]
          end
        end

      }.call(self.tablename) 
    end
    
    def self.columns
      return schema.nil? ? adapter.schema : schema['columns'] 
    end
    
    def columns
      self.class.columns
    end
    
    # get the list of fields to display in the given context
    # default context is :view, others could be :table, :form, :list 
    # or any specific context such as an action
    def self.fields_for_context(context = nil)
      self.fields[context] || self.fields[:view]
    end
    
    def fields_for_context(context = nil)
      self.class.fields_for_context context
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
      adapter.related options.merge :id => self.id, :instance => self     
    end
  
    # get the set of records from another class that are related to the
    # given instance through a bridging class i.e. many to many relationship
    # User -> UserGroups -> Group
    # options => {:relation => "group", :id => 123, :through => 'user_group'}
    # Group.where(:id => UserGroup.select(:group_id).where(:user_id => 123))
    def bridged options
      adapter.bridged options.merge :id => self.id, :instance => self
    end
  
    # get an array of entries that each contain the table ID and a 
    # human readable identifier (a title or name)
    def self.range
      adapter.range
    end
    
    private
      
    def is_a_known_attribute?(attr_name)
      
      if columns.is_a?(Hash)
        # column hash is keyed by column name
        columns.has_key?(attr_name) || columns.has_key?(attr_name.to_s)
      elsif columns.is_a?(Array)
        # column name is first element in each item
        columns.count{|item|item[0].to_s == attr_name.to_s} > 0
      end
      
    end
    
    def define_setter(attr_name)
      
      # define a dynamic setter which sets the attr_name value to the value given on invocation
      class_eval <<-RUBY
      def self.#{attr_name}=(value)        
        @values[attr_name] = value  
      end                           
      RUBY
    end
    
    def define_getter(attr_name)
      self.class.send :define_method, attr_name do
        @values[attr_name] || @values[attr_name.to_s]
      end
    end
    
    def method_missing(meth, *args, &block)
      
      # if this is an attribute setter then set the attribute value in the values hash
      if meth.to_s =~ /^(.+)=$/
        if is_a_known_attribute? $1
          @values.update($1 => args[0])
          define_setter($1)
          return
        end
        raise "unknown attribute #{$1}"
      end
      
      # if the method is a known attribute name then return the value
      if @values.has_key?(meth.to_s) || is_a_known_attribute?(meth.to_s)
        define_getter(meth)
        return @values[meth] || @values[meth.to_s]
      end
      
      # the method name is not a known attribute 
      if meth.to_s =~ /^find_by_(.+)$/
        run_find_by_method($1, *args, &block)
      else
        super # You *must* call super if you don't handle the
        # method, otherwise you'll mess up Ruby's method
        # lookup.
      end
    end

    def run_find_by_method(attrs, *args, &block)
      # Make an array of attribute names
      attrs = attrs.split('_and_')

      # #transpose will zip the two arrays together like so:
      #   [[:a, :b, :c], [1, 2, 3]].transpose
      #   # => [[:a, 1], [:b, 2], [:c, 3]]
      attrs_with_args = [attrs, args].transpose

      # Hash[] will take the passed associative array and turn it
      # into a hash like so:
      #   Hash[[[:a, 2], [:b, 4]]] # => { :a => 2, :b => 4 }
      conditions = Hash[attrs_with_args]

      # #where and #all are new AREL goodness that will find all
      # records matching our conditions
      adapter.where(conditions).all
    end
  end
end

