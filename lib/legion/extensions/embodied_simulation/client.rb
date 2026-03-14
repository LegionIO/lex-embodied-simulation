# frozen_string_literal: true

module Legion
  module Extensions
    module EmbodiedSimulation
      class Client
        include Runners::EmbodiedSimulation

        def initialize(engine: nil)
          @engine = engine || Helpers::SimulationEngine.new
        end
      end
    end
  end
end
