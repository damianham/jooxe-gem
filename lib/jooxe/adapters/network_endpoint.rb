require 'json'
require 'net/http'

module Jooxe
  # a class to access data via a remote web service
  # JSON is used for data transport

  class NetworkEndpoint
  
    # initialize with an endpoint that is setup with the base web service url
    # that includes the class name
    def initialize url
      @base_url = url
    end
  
    # create a new record
    def create input
    
      __make_request(:create, input) 

    end
  
    # save the given record
    def save input
    
      __make_request(:save, input)

    end

    # list records from the web service 
    def list(options = nil)
      __make_request(:list, options)
    
    end
    
    # get all records from the web service 
    def all
      __make_request(:all)
    
    end
  
    # find a set of records matching the given options
    def find(options)
      __make_request(:list, options)

    end
  
    # get a specific instance from the webservice
    def get options
      __make_request(:get, options)
    end

    # delete one or more records from the table
    def delete options
      result = __make_request(:delete, options)
    
      #return true if result == 1
      #false
      true
    end
  
    # get the set of columns in the table
    # returns a hash with the column name, datatype, size and tooltip
    def schema
      __make_request(:schema)
    end
  
    # get the set of records from another class that are related to the
    # given instance
    def related options
      __make_request(:related, options)
    end
  
    # get the set of records from another class that are related to the
    # given instance through a bridging class i.e.
    # User -> UserGroups -> Group
    def bridged options
      __make_request(:bridged, options)
    end
  
    # get an array of entries that each contain the table ID and a 
    # human readable identifier (a title or name)
    def range options
      __make_request(:range, options)
    end
  
    private
  
    def __make_request(action,options = nil)
    
      id = options[:id].nil? ? nil : options[:id].to_s
    
      url_path = [@base_url, id, action.to_s].compact.join('/')
    
      url = URI.encode(url_path)
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)

      headers = {'Remote-User' => ENV['REMOTE_USER'] || 'Anonymous',
        'Content-Type' => 'application/json'}

      if options.nil? 
        # response is a Net::HTTPResponse object
        response = http.start {|con| con.get(url, headers) }
      else
        data = JSON.encode(options)

        # response is a Net::HTTPResponse object
        response = http.start {|con| con.post(url, data, headers) }
      end

      case response
      when Net::HTTPSuccess
        # all requests to the web services return JSON

        #logger.warn(res.body)
        JSON.decode(response.body) rescue nil

      else
        raise Exception.new response.message
      end
     
    end
    
  end

end
