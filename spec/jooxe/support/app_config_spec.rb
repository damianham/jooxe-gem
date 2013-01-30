require 'spec_helper'

module Jooxe
  
  describe AppConfig do
    
    it "should set and retrieve a config value" do
      
      Jooxe.config.default_adapter = SequelAdapter
      
      adapter = Jooxe.config.default_adapter
      
      adapter.should eq(SequelAdapter)
      adapter.respond_to?(:tables).should be true
    end
    
    it "should reset the config values" do
      
      Jooxe.config.default_adapter = SequelAdapter
      Jooxe.config.reset_configs
      
      adapter = Jooxe.config.default_adapter
      
      adapter.should eq(nil)
      
    end
    
  end
  
end
  