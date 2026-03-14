# frozen_string_literal: true

module Legion
  module Extensions
    module EmbodiedSimulation
      module Helpers
        class Simulation
          include Constants

          attr_reader :id, :simulation_type, :domain, :initial_state, :steps,
                      :state, :outcome_valence, :fidelity, :created_at

          def initialize(id:, simulation_type:, domain:, initial_state:, fidelity: DEFAULT_FIDELITY)
            raise ArgumentError, "invalid type: #{simulation_type}" unless SIMULATION_TYPES.include?(simulation_type)

            @id              = id
            @simulation_type = simulation_type
            @domain          = domain
            @initial_state   = initial_state
            @steps           = []
            @state           = :pending
            @outcome_valence = nil
            @fidelity        = fidelity.to_f.clamp(FIDELITY_FLOOR, 1.0)
            @created_at      = Time.now.utc
          end

          def add_step(action:, expected_state:, confidence: DEFAULT_FIDELITY, somatic_signal: 0.0)
            return nil if @steps.size >= MAX_STEPS_PER_SIM
            return nil unless %i[pending running].include?(@state)

            @state = :running if @state == :pending
            step = SimulationStep.new(
              index: @steps.size, action: action, expected_state: expected_state,
              confidence: confidence, somatic_signal: somatic_signal
            )
            @steps << step
            step
          end

          def complete(valence:)
            return nil unless OUTCOME_VALENCES.include?(valence)
            return nil unless %i[pending running].include?(@state)

            @state           = :completed
            @outcome_valence = valence
          end

          def abort_simulation
            return nil if @state == :completed

            @state = :aborted
          end

          def fail_simulation
            return nil if @state == :completed

            @state = :failed
          end

          def running?
            @state == :running
          end

          def completed?
            @state == :completed
          end

          def successful?
            @state == :completed && @outcome_valence == :positive
          end

          def aggregate_somatic
            return 0.0 if @steps.empty?

            @steps.sum(&:somatic_signal) / @steps.size
          end

          def aggregate_confidence
            return 0.0 if @steps.empty?

            @steps.sum(&:confidence) / @steps.size
          end

          def negative_signals?
            @steps.any?(&:negative_signal?)
          end

          def step_count
            @steps.size
          end

          def counterfactual?
            @simulation_type == :counterfactual
          end

          def rehearsal?
            @simulation_type == :action_rehearsal
          end

          def empathic?
            @simulation_type == :empathic
          end

          def fidelity_label
            FIDELITY_LABELS.each { |range, lbl| return lbl if range.cover?(@fidelity) }
            :phantom
          end

          def decay_fidelity
            @fidelity = [@fidelity - FIDELITY_DECAY, FIDELITY_FLOOR].max
          end

          def to_h
            {
              id:              @id,
              simulation_type: @simulation_type,
              domain:          @domain,
              state:           @state,
              step_count:      @steps.size,
              outcome_valence: @outcome_valence,
              fidelity:        @fidelity.round(4),
              fidelity_label:  fidelity_label,
              somatic_avg:     aggregate_somatic.round(4),
              confidence_avg:  aggregate_confidence.round(4),
              created_at:      @created_at
            }
          end
        end
      end
    end
  end
end
