# frozen_string_literal: true

module Legion
  module Extensions
    module EmbodiedSimulation
      module Helpers
        module Constants
          MAX_SIMULATIONS = 30
          MAX_STEPS_PER_SIM = 20
          MAX_HISTORY = 200
          MAX_SCENARIOS = 50

          DEFAULT_FIDELITY = 0.5
          FIDELITY_FLOOR = 0.1
          FIDELITY_DECAY = 0.01
          FIDELITY_BOOST = 0.05

          OUTCOME_CONFIDENCE_FLOOR = 0.05
          CALIBRATION_ALPHA = 0.1

          SIMULATION_TYPES = %i[
            action_rehearsal counterfactual empathic
            predictive exploratory defensive
          ].freeze

          SIMULATION_STATES = %i[
            pending running completed failed aborted
          ].freeze

          OUTCOME_VALENCES = %i[
            positive negative neutral ambiguous
          ].freeze

          FIDELITY_LABELS = {
            (0.8..)     => :vivid,
            (0.6...0.8) => :clear,
            (0.4...0.6) => :hazy,
            (0.2...0.4) => :vague,
            (..0.2)     => :phantom
          }.freeze
        end
      end
    end
  end
end
