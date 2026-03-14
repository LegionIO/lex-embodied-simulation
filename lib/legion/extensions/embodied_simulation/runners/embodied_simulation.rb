# frozen_string_literal: true

module Legion
  module Extensions
    module EmbodiedSimulation
      module Runners
        module EmbodiedSimulation
          include Helpers::Constants

          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def create_simulation(simulation_type:, domain:, initial_state: {}, fidelity: DEFAULT_FIDELITY, **)
            sim = engine.create_simulation(
              simulation_type: simulation_type, domain: domain,
              initial_state: initial_state, fidelity: fidelity
            )
            return { success: false, reason: :limit_or_invalid_type } unless sim

            { success: true, simulation_id: sim.id, simulation_type: sim.simulation_type, domain: sim.domain }
          end

          def add_simulation_step(sim_id:, action:, expected_state: {}, confidence: DEFAULT_FIDELITY,
                                  somatic_signal: 0.0, **)
            step = engine.add_step(
              sim_id: sim_id, action: action, expected_state: expected_state,
              confidence: confidence, somatic_signal: somatic_signal
            )
            return { success: false, reason: :not_found_or_full } unless step

            { success: true, step_index: step.index, action: step.action }
          end

          def complete_simulation(sim_id:, valence:, **)
            result = engine.complete_simulation(sim_id: sim_id, valence: valence)
            return { success: false, reason: :not_found_or_invalid } unless result

            { success: true, simulation_id: sim_id, valence: valence }
          end

          def rehearse_action(domain:, action_sequence:, initial_state: {}, **)
            sim = engine.rehearse(domain: domain, action_sequence: action_sequence, initial_state: initial_state)
            return { success: false, reason: :limit_reached } unless sim

            { success: true, simulation_id: sim.id, step_count: sim.step_count,
              somatic_avg: sim.aggregate_somatic.round(4) }
          end

          def run_counterfactual(domain:, actual_outcome:, alternative_actions:, initial_state: {}, **)
            sim = engine.counterfactual(
              domain: domain, actual_outcome: actual_outcome,
              alternative_actions: alternative_actions, initial_state: initial_state
            )
            return { success: false, reason: :limit_reached } unless sim

            { success: true, simulation_id: sim.id, step_count: sim.step_count }
          end

          def evaluate_simulation(sim_id:, **)
            result = engine.evaluate_simulation(sim_id: sim_id)
            return { success: false, reason: :not_found } unless result

            { success: true }.merge(result)
          end

          def compare_simulations(sim_ids:, **)
            ranked = engine.compare_simulations(*sim_ids)
            { success: true, ranked: ranked, count: ranked.size }
          end

          def calibrate_simulation(sim_id:, actual_valence:, **)
            label = engine.calibrate(sim_id: sim_id, actual_valence: actual_valence)
            return { success: false, reason: :not_found_or_incomplete } unless label

            { success: true, calibration: engine.calibration.round(4), fidelity_label: label }
          end

          def update_embodied_simulation(**)
            engine.decay_all
            { success: true }.merge(engine.to_h)
          end

          def embodied_simulation_stats(**)
            { success: true }.merge(engine.to_h)
          end

          private

          def engine
            @engine ||= Helpers::SimulationEngine.new
          end
        end
      end
    end
  end
end
