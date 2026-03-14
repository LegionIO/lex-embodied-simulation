# frozen_string_literal: true

module Legion
  module Extensions
    module EmbodiedSimulation
      module Helpers
        class SimulationEngine
          include Constants

          attr_reader :simulations, :history, :calibration

          def initialize
            @simulations = {}
            @counter     = 0
            @history     = []
            @calibration = 0.5
          end

          def create_simulation(simulation_type:, domain:, initial_state:, fidelity: DEFAULT_FIDELITY)
            return nil unless SIMULATION_TYPES.include?(simulation_type)
            return nil if @simulations.size >= MAX_SIMULATIONS

            @counter += 1
            sim_id = :"sim_#{@counter}"
            sim = Simulation.new(
              id: sim_id, simulation_type: simulation_type,
              domain: domain, initial_state: initial_state, fidelity: fidelity
            )
            @simulations[sim_id] = sim
            sim
          end

          def add_step(sim_id:, action:, expected_state:, confidence: DEFAULT_FIDELITY, somatic_signal: 0.0)
            sim = @simulations[sim_id]
            return nil unless sim

            sim.add_step(action: action, expected_state: expected_state,
                         confidence: confidence, somatic_signal: somatic_signal)
          end

          def complete_simulation(sim_id:, valence:)
            sim = @simulations[sim_id]
            return nil unless sim

            result = sim.complete(valence: valence)
            record_completion(sim) if result
            result
          end

          def abort_simulation(sim_id:)
            sim = @simulations[sim_id]
            return nil unless sim

            sim.abort_simulation
          end

          def rehearse(domain:, action_sequence:, initial_state: {})
            sim = create_simulation(
              simulation_type: :action_rehearsal, domain: domain,
              initial_state: initial_state
            )
            return nil unless sim

            run_sequence(sim, action_sequence)
            sim
          end

          def counterfactual(domain:, actual_outcome:, alternative_actions:, initial_state: {})
            sim = create_simulation(
              simulation_type: :counterfactual, domain: domain,
              initial_state: initial_state.merge(actual_outcome: actual_outcome)
            )
            return nil unless sim

            run_sequence(sim, alternative_actions)
            sim
          end

          def evaluate_simulation(sim_id:)
            sim = @simulations[sim_id]
            return nil unless sim

            build_evaluation(sim)
          end

          def compare_simulations(*sim_ids)
            sims = sim_ids.filter_map { |id| @simulations[id] }
            return [] if sims.empty?

            sims.sort_by { |s| -(s.aggregate_somatic + s.aggregate_confidence) }.map(&:to_h)
          end

          def simulations_for(domain:)
            @simulations.values.select { |s| s.domain == domain }.map(&:to_h)
          end

          def active_simulations
            @simulations.values.select(&:running?).map(&:to_h)
          end

          def completed_simulations
            @simulations.values.select(&:completed?).map(&:to_h)
          end

          def calibrate(sim_id:, actual_valence:)
            sim = @simulations[sim_id]
            return nil unless sim&.completed?

            match = sim.outcome_valence == actual_valence ? 1.0 : 0.0
            @calibration += CALIBRATION_ALPHA * (match - @calibration)
            @calibration = @calibration.clamp(0.0, 1.0)
            sim.fidelity_label
          end

          def decay_all
            @simulations.each_value(&:decay_fidelity)
            @simulations.reject! { |_, s| s.fidelity <= FIDELITY_FLOOR && s.completed? }
          end

          def to_h
            {
              simulation_count: @simulations.size,
              active_count:     @simulations.values.count(&:running?),
              completed_count:  @simulations.values.count(&:completed?),
              calibration:      @calibration.round(4),
              history_size:     @history.size
            }
          end

          private

          def run_sequence(sim, actions)
            actions.each_with_index do |act, _i|
              sim.add_step(
                action:         act[:action] || act,
                expected_state: act[:expected_state] || {},
                confidence:     act[:confidence] || DEFAULT_FIDELITY,
                somatic_signal: act[:somatic_signal] || 0.0
              )
            end
          end

          def record_completion(sim)
            @history << {
              id:      sim.id, type: sim.simulation_type, domain: sim.domain,
              valence: sim.outcome_valence, steps: sim.step_count, at: Time.now.utc
            }
            @history.shift while @history.size > MAX_HISTORY
          end

          def build_evaluation(sim)
            {
              id:             sim.id,
              state:          sim.state,
              recommendation: recommend(sim),
              somatic_avg:    sim.aggregate_somatic.round(4),
              confidence_avg: sim.aggregate_confidence.round(4),
              has_warnings:   sim.negative_signals?,
              fidelity:       sim.fidelity.round(4),
              step_count:     sim.step_count
            }
          end

          def recommend(sim)
            return :insufficient_data if sim.steps.empty?
            return :abort if sim.aggregate_somatic < -0.5
            return :proceed_with_caution if sim.negative_signals?
            return :proceed if sim.aggregate_somatic >= 0.0 && sim.aggregate_confidence >= 0.5

            :reconsider
          end
        end
      end
    end
  end
end
