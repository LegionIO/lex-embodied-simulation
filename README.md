# lex-embodied-simulation

Embodied cognition simulation for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models the theory that cognition is grounded in sensorimotor experience. Simulates a body schema with sensory channels and motor programs. Runs mental simulations of actions before execution, using learned somatic markers (body-based memories of action outcomes) to predict how an action will feel and whether it is safe to execute. Tracks proprioceptive state including posture, energy, and grounding.

Based on Lakoff and Johnson's embodied cognition theory and Damasio's somatic marker hypothesis.

## Usage

```ruby
client = Legion::Extensions::EmbodiedSimulation::Client.new

# Update sensory input
client.update_sensory_state(channel: :visual, intensity: 0.8, valence: 0.5)
client.update_sensory_state(channel: :interoceptive, intensity: 0.6, valence: -0.2)

# Simulate an action before executing it
client.simulate_action(action: :approach, context: { target: 'user_request' })
# => { success: true, action: :approach, predicted_outcome: :positive,
#      somatic_response: 0.3, grounded: true, confidence: 0.75 }

# Execute a motor program
client.execute_motor_program(program: :approach, intensity: 0.7)
# => { success: true, program: :approach, executed: true, energy_cost: 0.07, energy_remaining: 0.93 }

# Record the outcome as a somatic marker for future simulations
client.record_somatic_marker(action: :approach, outcome: :positive, valence: 0.6)

# Check body state
client.proprioceptive_state
# => { posture: :upright, energy: 0.93, comfort: 0.7, grounding_score: 0.8 }

# Simulate a sequence of actions
client.simulate_sequence(actions: [:orient, :approach, :manipulate])
# => { success: true, feasible: true, total_energy_cost: 0.21, sequence: [...] }

# Rest to recover energy
client.rest_body
# => { success: true, energy_before: 0.4, energy_after: 0.5, recovered: 0.1 }

# Periodic maintenance
client.update_embodied_simulation
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
