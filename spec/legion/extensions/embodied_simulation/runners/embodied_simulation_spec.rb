# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmbodiedSimulation::Runners::EmbodiedSimulation do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#create_simulation' do
    it 'creates successfully' do
      result = runner.create_simulation(simulation_type: :action_rehearsal, domain: :nav, initial_state: {})
      expect(result[:success]).to be true
      expect(result[:simulation_id]).to be_a(Symbol)
    end

    it 'returns failure for invalid type' do
      result = runner.create_simulation(simulation_type: :bogus, domain: :x, initial_state: {})
      expect(result[:success]).to be false
    end
  end

  describe '#add_simulation_step' do
    it 'adds step to existing sim' do
      created = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      result = runner.add_simulation_step(sim_id: created[:simulation_id], action: :go, expected_state: {})
      expect(result[:success]).to be true
      expect(result[:step_index]).to eq(0)
    end

    it 'returns failure for unknown sim' do
      result = runner.add_simulation_step(sim_id: :bogus, action: :go, expected_state: {})
      expect(result[:success]).to be false
    end
  end

  describe '#complete_simulation' do
    it 'completes successfully' do
      created = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      result = runner.complete_simulation(sim_id: created[:simulation_id], valence: :positive)
      expect(result[:success]).to be true
    end
  end

  describe '#rehearse_action' do
    it 'runs a rehearsal' do
      actions = [{ action: :step_one, expected_state: { pos: 1 } }]
      result = runner.rehearse_action(domain: :nav, action_sequence: actions)
      expect(result[:success]).to be true
      expect(result[:step_count]).to eq(1)
    end
  end

  describe '#run_counterfactual' do
    it 'runs a counterfactual' do
      alts = [{ action: :alt, expected_state: {} }]
      result = runner.run_counterfactual(domain: :decision, actual_outcome: :bad, alternative_actions: alts)
      expect(result[:success]).to be true
    end
  end

  describe '#evaluate_simulation' do
    it 'evaluates a simulation' do
      created = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      sid = created[:simulation_id]
      runner.add_simulation_step(sim_id: sid, action: :go, expected_state: {}, confidence: 0.8, somatic_signal: 0.5)
      result = runner.evaluate_simulation(sim_id: sid)
      expect(result[:success]).to be true
      expect(result[:recommendation]).to eq(:proceed)
    end

    it 'returns failure for unknown sim' do
      result = runner.evaluate_simulation(sim_id: :bogus)
      expect(result[:success]).to be false
    end
  end

  describe '#compare_simulations' do
    it 'compares and ranks' do
      a = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      runner.add_simulation_step(sim_id: a[:simulation_id], action: :a, expected_state: {},
                                 confidence: 0.9, somatic_signal: 0.8)
      b = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      runner.add_simulation_step(sim_id: b[:simulation_id], action: :b, expected_state: {},
                                 confidence: 0.3, somatic_signal: -0.2)
      result = runner.compare_simulations(sim_ids: [a[:simulation_id], b[:simulation_id]])
      expect(result[:success]).to be true
      expect(result[:ranked].first[:id]).to eq(a[:simulation_id])
    end
  end

  describe '#calibrate_simulation' do
    it 'calibrates after completion' do
      created = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      sid = created[:simulation_id]
      runner.complete_simulation(sim_id: sid, valence: :positive)
      result = runner.calibrate_simulation(sim_id: sid, actual_valence: :positive)
      expect(result[:success]).to be true
      expect(result[:calibration]).to be > 0.5
    end

    it 'returns failure for incomplete sim' do
      created = runner.create_simulation(simulation_type: :action_rehearsal, domain: :x, initial_state: {})
      result = runner.calibrate_simulation(sim_id: created[:simulation_id], actual_valence: :positive)
      expect(result[:success]).to be false
    end
  end

  describe '#update_embodied_simulation' do
    it 'ticks and returns stats' do
      result = runner.update_embodied_simulation
      expect(result[:success]).to be true
      expect(result).to include(:simulation_count, :calibration)
    end
  end

  describe '#embodied_simulation_stats' do
    it 'returns stats' do
      result = runner.embodied_simulation_stats
      expect(result[:success]).to be true
      expect(result[:simulation_count]).to eq(0)
    end
  end
end
