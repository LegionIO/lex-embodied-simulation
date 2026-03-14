# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmbodiedSimulation::Helpers::Simulation do
  subject(:sim) do
    described_class.new(
      id: :sim_one, simulation_type: :action_rehearsal,
      domain: :navigation, initial_state: { pos: 0 }
    )
  end

  describe '#initialize' do
    it 'sets id and type' do
      expect(sim.id).to eq(:sim_one)
      expect(sim.simulation_type).to eq(:action_rehearsal)
    end

    it 'starts in pending state' do
      expect(sim.state).to eq(:pending)
    end

    it 'starts with empty steps' do
      expect(sim.steps).to be_empty
    end

    it 'rejects invalid simulation type' do
      expect do
        described_class.new(id: :x, simulation_type: :bogus, domain: :d, initial_state: {})
      end.to raise_error(ArgumentError)
    end

    it 'clamps fidelity to floor' do
      s = described_class.new(id: :x, simulation_type: :predictive, domain: :d, initial_state: {}, fidelity: 0.0)
      expect(s.fidelity).to eq(0.1)
    end
  end

  describe '#add_step' do
    it 'adds a step and transitions to running' do
      step = sim.add_step(action: :go, expected_state: { pos: 1 })
      expect(step).to be_a(Legion::Extensions::EmbodiedSimulation::Helpers::SimulationStep)
      expect(sim.state).to eq(:running)
    end

    it 'enforces MAX_STEPS_PER_SIM' do
      20.times { |i| sim.add_step(action: :"step_#{i}", expected_state: {}) }
      expect(sim.add_step(action: :overflow, expected_state: {})).to be_nil
    end

    it 'rejects steps after completion' do
      sim.complete(valence: :positive)
      expect(sim.add_step(action: :late, expected_state: {})).to be_nil
    end
  end

  describe '#complete' do
    it 'sets state to completed and records valence' do
      sim.complete(valence: :positive)
      expect(sim.completed?).to be true
      expect(sim.outcome_valence).to eq(:positive)
    end

    it 'rejects invalid valence' do
      expect(sim.complete(valence: :bogus)).to be_nil
    end

    it 'rejects completing an already completed simulation' do
      sim.complete(valence: :positive)
      expect(sim.complete(valence: :negative)).to be_nil
    end
  end

  describe '#abort_simulation' do
    it 'sets state to aborted' do
      sim.abort_simulation
      expect(sim.state).to eq(:aborted)
    end

    it 'does not abort completed sim' do
      sim.complete(valence: :neutral)
      expect(sim.abort_simulation).to be_nil
    end
  end

  describe '#fail_simulation' do
    it 'sets state to failed' do
      sim.fail_simulation
      expect(sim.state).to eq(:failed)
    end
  end

  describe '#aggregate_somatic' do
    it 'returns 0.0 for empty steps' do
      expect(sim.aggregate_somatic).to eq(0.0)
    end

    it 'averages somatic signals' do
      sim.add_step(action: :a, expected_state: {}, somatic_signal: 0.5)
      sim.add_step(action: :b, expected_state: {}, somatic_signal: -0.5)
      expect(sim.aggregate_somatic).to eq(0.0)
    end
  end

  describe '#aggregate_confidence' do
    it 'averages step confidences' do
      sim.add_step(action: :a, expected_state: {}, confidence: 0.8)
      sim.add_step(action: :b, expected_state: {}, confidence: 0.4)
      expect(sim.aggregate_confidence).to be_within(0.001).of(0.6)
    end
  end

  describe '#negative_signals?' do
    it 'returns false without negative steps' do
      sim.add_step(action: :a, expected_state: {}, somatic_signal: 0.5)
      expect(sim.negative_signals?).to be false
    end

    it 'returns true with a negative step' do
      sim.add_step(action: :a, expected_state: {}, somatic_signal: -0.5)
      expect(sim.negative_signals?).to be true
    end
  end

  describe '#successful?' do
    it 'returns true for completed + positive' do
      sim.complete(valence: :positive)
      expect(sim.successful?).to be true
    end

    it 'returns false for completed + negative' do
      sim.complete(valence: :negative)
      expect(sim.successful?).to be false
    end
  end

  describe 'type predicates' do
    it 'rehearsal? for action_rehearsal' do
      expect(sim.rehearsal?).to be true
      expect(sim.counterfactual?).to be false
    end

    it 'counterfactual?' do
      s = described_class.new(id: :x, simulation_type: :counterfactual, domain: :d, initial_state: {})
      expect(s.counterfactual?).to be true
    end

    it 'empathic?' do
      s = described_class.new(id: :x, simulation_type: :empathic, domain: :d, initial_state: {})
      expect(s.empathic?).to be true
    end
  end

  describe '#fidelity_label' do
    it 'returns a symbol' do
      expect(sim.fidelity_label).to be_a(Symbol)
    end
  end

  describe '#decay_fidelity' do
    it 'reduces fidelity' do
      original = sim.fidelity
      sim.decay_fidelity
      expect(sim.fidelity).to be < original
    end

    it 'does not go below floor' do
      50.times { sim.decay_fidelity }
      expect(sim.fidelity).to eq(0.1)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = sim.to_h
      expect(h).to include(:id, :simulation_type, :domain, :state, :step_count,
                           :outcome_valence, :fidelity, :fidelity_label)
    end
  end
end
