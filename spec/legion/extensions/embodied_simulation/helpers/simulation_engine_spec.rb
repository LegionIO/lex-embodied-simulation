# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmbodiedSimulation::Helpers::SimulationEngine do
  subject(:engine) { described_class.new }

  describe '#create_simulation' do
    it 'creates a simulation' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :nav, initial_state: {})
      expect(sim).to be_a(Legion::Extensions::EmbodiedSimulation::Helpers::Simulation)
      expect(sim.id).to be_a(Symbol)
    end

    it 'rejects invalid types' do
      expect(engine.create_simulation(simulation_type: :bogus, domain: :x, initial_state: {})).to be_nil
    end

    it 'enforces MAX_SIMULATIONS' do
      30.times { |i| engine.create_simulation(simulation_type: :predictive, domain: :"d_#{i}", initial_state: {}) }
      expect(engine.create_simulation(simulation_type: :predictive, domain: :overflow, initial_state: {})).to be_nil
    end
  end

  describe '#add_step' do
    it 'adds step to existing simulation' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      step = engine.add_step(sim_id: sim.id, action: :go, expected_state: { pos: 1 })
      expect(step.action).to eq(:go)
    end

    it 'returns nil for unknown sim' do
      expect(engine.add_step(sim_id: :bogus, action: :go, expected_state: {})).to be_nil
    end
  end

  describe '#complete_simulation' do
    it 'completes and records in history' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.complete_simulation(sim_id: sim.id, valence: :positive)
      expect(engine.history.size).to eq(1)
      expect(engine.history.first[:valence]).to eq(:positive)
    end

    it 'returns nil for unknown sim' do
      expect(engine.complete_simulation(sim_id: :bogus, valence: :positive)).to be_nil
    end
  end

  describe '#abort_simulation' do
    it 'aborts a simulation' do
      sim = engine.create_simulation(simulation_type: :exploratory, domain: :x, initial_state: {})
      engine.abort_simulation(sim_id: sim.id)
      expect(sim.state).to eq(:aborted)
    end
  end

  describe '#rehearse' do
    it 'creates and runs an action rehearsal' do
      actions = [
        { action: :step_one, expected_state: { pos: 1 }, confidence: 0.8, somatic_signal: 0.3 },
        { action: :step_two, expected_state: { pos: 2 }, confidence: 0.6, somatic_signal: -0.1 }
      ]
      sim = engine.rehearse(domain: :navigation, action_sequence: actions)
      expect(sim.simulation_type).to eq(:action_rehearsal)
      expect(sim.step_count).to eq(2)
    end

    it 'returns nil when limit reached' do
      30.times { |i| engine.create_simulation(simulation_type: :predictive, domain: :"d_#{i}", initial_state: {}) }
      expect(engine.rehearse(domain: :x, action_sequence: [{ action: :a }])).to be_nil
    end
  end

  describe '#counterfactual' do
    it 'creates a counterfactual simulation' do
      alts = [{ action: :alt_a, expected_state: { result: :better } }]
      sim = engine.counterfactual(domain: :decision, actual_outcome: :bad, alternative_actions: alts)
      expect(sim.simulation_type).to eq(:counterfactual)
      expect(sim.initial_state[:actual_outcome]).to eq(:bad)
    end
  end

  describe '#evaluate_simulation' do
    it 'evaluates a simulation with steps' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.add_step(sim_id: sim.id, action: :go, expected_state: {}, confidence: 0.8, somatic_signal: 0.5)
      result = engine.evaluate_simulation(sim_id: sim.id)
      expect(result[:recommendation]).to eq(:proceed)
    end

    it 'returns :insufficient_data for empty sim' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      result = engine.evaluate_simulation(sim_id: sim.id)
      expect(result[:recommendation]).to eq(:insufficient_data)
    end

    it 'returns :abort for very negative somatic' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.add_step(sim_id: sim.id, action: :bad, expected_state: {}, somatic_signal: -0.8)
      result = engine.evaluate_simulation(sim_id: sim.id)
      expect(result[:recommendation]).to eq(:abort)
    end

    it 'returns :proceed_with_caution for mixed signals' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.add_step(sim_id: sim.id, action: :ok, expected_state: {}, somatic_signal: 0.5, confidence: 0.8)
      engine.add_step(sim_id: sim.id, action: :risky, expected_state: {}, somatic_signal: -0.4, confidence: 0.6)
      result = engine.evaluate_simulation(sim_id: sim.id)
      expect(result[:recommendation]).to eq(:proceed_with_caution)
    end

    it 'returns nil for unknown sim' do
      expect(engine.evaluate_simulation(sim_id: :bogus)).to be_nil
    end
  end

  describe '#compare_simulations' do
    it 'ranks simulations by combined score' do
      sim_a = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.add_step(sim_id: sim_a.id, action: :a, expected_state: {}, confidence: 0.9, somatic_signal: 0.8)
      sim_b = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.add_step(sim_id: sim_b.id, action: :b, expected_state: {}, confidence: 0.3, somatic_signal: -0.2)

      ranked = engine.compare_simulations(sim_a.id, sim_b.id)
      expect(ranked.first[:id]).to eq(sim_a.id)
    end

    it 'returns empty for no matches' do
      expect(engine.compare_simulations(:x, :y)).to eq([])
    end
  end

  describe '#simulations_for' do
    it 'filters by domain' do
      engine.create_simulation(simulation_type: :predictive, domain: :nav, initial_state: {})
      engine.create_simulation(simulation_type: :predictive, domain: :social, initial_state: {})
      expect(engine.simulations_for(domain: :nav).size).to eq(1)
    end
  end

  describe '#active_simulations' do
    it 'returns running simulations' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.add_step(sim_id: sim.id, action: :go, expected_state: {})
      expect(engine.active_simulations.size).to eq(1)
    end
  end

  describe '#completed_simulations' do
    it 'returns completed simulations' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.complete_simulation(sim_id: sim.id, valence: :positive)
      expect(engine.completed_simulations.size).to eq(1)
    end
  end

  describe '#calibrate' do
    it 'increases calibration on correct prediction' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.complete_simulation(sim_id: sim.id, valence: :positive)
      initial = engine.calibration
      engine.calibrate(sim_id: sim.id, actual_valence: :positive)
      expect(engine.calibration).to be > initial
    end

    it 'decreases calibration on incorrect prediction' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      engine.complete_simulation(sim_id: sim.id, valence: :positive)
      initial = engine.calibration
      engine.calibrate(sim_id: sim.id, actual_valence: :negative)
      expect(engine.calibration).to be < initial
    end

    it 'returns nil for incomplete sim' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      expect(engine.calibrate(sim_id: sim.id, actual_valence: :positive)).to be_nil
    end
  end

  describe '#decay_all' do
    it 'decays fidelity on all simulations' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {}, fidelity: 0.3)
      original = sim.fidelity
      engine.decay_all
      expect(sim.fidelity).to be < original
    end

    it 'removes faded completed simulations' do
      sim = engine.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {}, fidelity: 0.11)
      engine.complete_simulation(sim_id: sim.id, valence: :neutral)
      engine.decay_all
      expect(engine.simulations).to be_empty
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = engine.to_h
      expect(h).to include(:simulation_count, :active_count, :completed_count, :calibration, :history_size)
    end
  end
end
