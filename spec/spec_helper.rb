# frozen_string_literal: true

require 'legion/extensions/embodied_simulation/version'
require 'legion/extensions/embodied_simulation/helpers/constants'
require 'legion/extensions/embodied_simulation/helpers/simulation_step'
require 'legion/extensions/embodied_simulation/helpers/simulation'
require 'legion/extensions/embodied_simulation/helpers/simulation_engine'
require 'legion/extensions/embodied_simulation/runners/embodied_simulation'
require 'legion/extensions/embodied_simulation/client'

module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

module Legion
  module Logging
    def self.method_missing(*); end
    def self.respond_to_missing?(*) = true
  end
end
