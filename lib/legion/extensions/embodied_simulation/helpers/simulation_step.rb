# frozen_string_literal: true

module Legion
  module Extensions
    module EmbodiedSimulation
      module Helpers
        class SimulationStep
          include Constants

          attr_reader :index, :action, :expected_state, :confidence, :somatic_signal

          def initialize(index:, action:, expected_state:, confidence: DEFAULT_FIDELITY, somatic_signal: 0.0)
            @index          = index
            @action         = action
            @expected_state = expected_state
            @confidence     = confidence.to_f.clamp(0.0, 1.0)
            @somatic_signal = somatic_signal.to_f.clamp(-1.0, 1.0)
          end

          def positive_signal?
            @somatic_signal > 0.2
          end

          def negative_signal?
            @somatic_signal < -0.2
          end

          def high_confidence?
            @confidence >= 0.7
          end

          def to_h
            {
              index:          @index,
              action:         @action,
              expected_state: @expected_state,
              confidence:     @confidence.round(4),
              somatic_signal: @somatic_signal.round(4)
            }
          end
        end
      end
    end
  end
end
