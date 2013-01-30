

module Jooxe
  module Adapter
    
    # Factory method to instantiate a storage adapter for a given class
    def adapter_for_class klass
      tablename = klass.tablename || klass.name.demodulize.tableize
      
      case klass.adapter_type
      when :sequel
        adapter = SequelAdapter.new tablename, klass
      when :network
        raise Exception "Network endpoint must be specified for #{tablename}" unless klass.endpoint
        endpoint = NetworkEndpoint.new klass.endpoint + '/' + tablename
        adapter = NetworkAdapter.new endpoint, klass
      else
        default_class = Jooxe.config.default_adapter || SequelAdapter
        default_class =  SequelAdapter unless default_class.respond_to?(:tables)
         
        adapter = default_class.new klass, klass
      end
      adapter
    end
  end
end