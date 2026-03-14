# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmbodiedSimulation::Client do
  subject(:client) { described_class.new }

  it 'creates and evaluates a simulation lifecycle' do
    result = client.create_simulation(simulation_type: :action_rehearsal, domain: :nav, initial_state: {})
    expect(result[:success]).to be true
    sim_id = result[:simulation_id]

    client.add_simulation_step(sim_id: sim_id, action: :move, expected_state: { pos: 1 },
                               confidence: 0.8, somatic_signal: 0.4)
    eval_result = client.evaluate_simulation(sim_id: sim_id)
    expect(eval_result[:recommendation]).to eq(:proceed)

    client.complete_simulation(sim_id: sim_id, valence: :positive)
    cal = client.calibrate_simulation(sim_id: sim_id, actual_valence: :positive)
    expect(cal[:calibration]).to be > 0.5
  end

  it 'runs rehearsal and counterfactual' do
    rehearsal = client.rehearse_action(
      domain:          :task,
      action_sequence: [
        { action: :step_one, expected_state: { done: true }, confidence: 0.9, somatic_signal: 0.3 }
      ]
    )
    expect(rehearsal[:success]).to be true

    counter = client.run_counterfactual(
      domain:              :decision,
      actual_outcome:      :failure,
      alternative_actions: [{ action: :alt_path, expected_state: { done: true } }]
    )
    expect(counter[:success]).to be true
  end

  it 'accepts injected engine' do
    engine = Legion::Extensions::EmbodiedSimulation::Helpers::SimulationEngine.new
    c = described_class.new(engine: engine)
    c.create_simulation(simulation_type: :exploratory, domain: :x, initial_state: {})
    expect(engine.simulations.size).to eq(1)
  end
end
