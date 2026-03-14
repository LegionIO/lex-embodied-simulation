# lex-embodied-simulation

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Embodied cognition simulation for the LegionIO cognitive architecture. Models the theory that cognition is grounded in physical/sensorimotor experience rather than purely abstract symbol manipulation. Simulates a body schema with sensory channels and motor programs, runs mental simulations of actions before execution, and tracks proprioceptive state (posture, energy, comfort, grounding).

Based on Lakoff and Johnson's embodied cognition theory and Damasio's somatic marker hypothesis.

## Gem Info

- **Gem name**: `lex-embodied-simulation`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::EmbodiedSimulation`
- **Location**: `extensions-agentic/lex-embodied-simulation/`

## File Structure

```
lib/legion/extensions/embodied_simulation/
  embodied_simulation.rb        # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # SENSORY_CHANNELS, MOTOR_PROGRAMS, POSTURE_STATES, thresholds
    body_schema.rb              # BodySchema: sensory state, motor state, proprioception
    simulation_engine.rb        # Engine: simulations, somatic markers, grounding
  runners/
    embodied_simulation.rb      # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `SENSORY_CHANNELS` | `[:visual, :auditory, :tactile, :proprioceptive, :interoceptive]` | Valid sensory modalities |
| `MOTOR_PROGRAMS` | `[:approach, :avoid, :manipulate, :orient, :freeze]` | Valid motor action types |
| `POSTURE_STATES` | `[:upright, :forward_lean, :retreat, :closed, :open]` | Body posture encoding |
| `SIMULATION_DEPTH` | 3 | Max forward simulation steps |
| `GROUNDING_THRESHOLD` | 0.4 | Minimum grounding score for confident action |
| `ENERGY_DECAY_RATE` | 0.05 | Energy depleted per simulation cycle |
| `ENERGY_RECOVERY_RATE` | 0.1 | Energy recovered per rest cycle |
| `SOMATIC_MARKER_STRENGTH` | 0.3 | Weight of somatic markers in action evaluation |
| `MAX_SIMULATIONS` | 200 | Rolling simulation history cap |
| `MAX_SOMATIC_MARKERS` | 100 | Somatic marker store cap |

## Runners

All methods in `Legion::Extensions::EmbodiedSimulation::Runners::EmbodiedSimulation`.

| Method | Key Args | Returns |
|---|---|---|
| `update_sensory_state` | `channel:, intensity:, valence: 0.0` | `{ success:, channel:, intensity:, body_state: }` |
| `simulate_action` | `action:, context: {}` | `{ success:, action:, predicted_outcome:, somatic_response:, grounded:, confidence: }` |
| `execute_motor_program` | `program:, intensity: 1.0` | `{ success:, program:, executed:, energy_cost:, energy_remaining: }` |
| `update_posture` | `posture:` | `{ success:, posture:, previous_posture: }` |
| `record_somatic_marker` | `action:, outcome:, valence:` | `{ success:, marker_id:, action:, valence: }` |
| `proprioceptive_state` | — | `{ success:, posture:, energy:, comfort:, grounding_score: }` |
| `grounded_concepts` | `concept: nil` | `{ success:, concepts:, count: }` |
| `simulate_sequence` | `actions:, context: {}` | `{ success:, sequence:, total_energy_cost:, feasible: }` |
| `rest_body` | — | `{ success:, energy_before:, energy_after:, recovered: }` |
| `update_embodied_simulation` | — | `{ success:, energy_recovered:, markers_pruned: }` |
| `embodied_simulation_stats` | — | Full stats hash |

## Helpers

### `BodySchema`
Central body state. Attributes: `@sensory_state` (hash by channel, intensity+valence), `@motor_state` (last executed program), `@posture`, `@energy` (float 0–1), `@comfort` (float 0–1), `@grounding_score`. Methods: `update_channel(channel:, intensity:, valence:)`, `execute_program(program:, intensity:)`, `update_posture(posture:)`, `rest` (recover energy), `body_state` (summary hash).

### `SimulationEngine`
Simulation runner + somatic marker store. Key methods:
- `simulate(action:, context:)`: looks up somatic markers for action, computes predicted outcome, grounding from energy and marker confidence, returns simulation result
- `simulate_sequence(actions:, context:)`: runs `simulate` for each action sequentially, tracks cumulative energy cost
- `record_marker(action:, outcome:, valence:)`: stores SomaticMarker associating action with felt outcome
- `grounded_concepts`: returns all concepts with associated somatic markers (grouped by action)
- `markers_for(action:)`: retrieves somatic markers for a specific action, sorted by recency

## Integration Points

- `proprioceptive_state[:grounding_score]` feeds lex-emotion as a stability/comfort signal
- `simulate_action` informs lex-tick's `action_selection` phase — low grounding suppresses risky actions
- `somatic_response` from simulation feeds lex-emotion gut instinct channel
- `energy_remaining` maps to lex-fatigue's physical fatigue dimension
- `update_embodied_simulation` maps to lex-tick's periodic maintenance cycle

## Development Notes

- Grounding score is derived from energy level and somatic marker confidence, not from external feedback
- Motor program execution always succeeds (no collision detection) — energy cost is the only gate
- Somatic markers persist until pruned by `update_embodied_simulation` (removes low-confidence markers)
- `simulate_sequence` stops early if cumulative energy cost would exceed current energy level
- SIMULATION_DEPTH controls forward planning horizon but the current implementation does single-step simulation per action
