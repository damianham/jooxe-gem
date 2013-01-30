require 'jooxe/model'

module Jooxe
  class ApplicationConfig < Jooxe::Model
=begin
  serialize :config_value

  after_save :reset_config

  def reset_config

    Jooxe.config.reset_configs

  end

=end
  end

end
