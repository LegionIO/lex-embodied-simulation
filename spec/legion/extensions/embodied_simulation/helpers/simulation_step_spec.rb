# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmbodiedSimulation::Helpers::SimulationStep do
  subject(:step) do
    described_class.new(
      index: 0, action: :move_forward,
      expected_state: { position: 1 },
      confidence: 0.7, somatic_signal: 0.3
    )
  end

  describe '#initialize' do
    it 'sets index' do
      expect(step.index).to eq(0)
    end

    it 'sets action' do
      expect(step.action).to eq(:move_forward)
    end

    it 'sets expected_state' do
      expect(step.expected_state).to eq({ position: 1 })
    end

    it 'sets confidence' do
      expect(step.confidence).to eq(0.7)
    end

    it 'sets somatic_signal' do
      expect(step.somatic_signal).to eq(0.3)
    end

    it 'clamps confidence to 0..1' do
      s = described_class.new(index: 0, action: :x, expected_state: {}, confidence: 2.0)
      expect(s.confidence).to eq(1.0)
    end

    it 'clamps somatic_signal to -1..1' do
      s = described_class.new(index: 0, action: :x, expected_state: {}, somatic_signal: -5.0)
      expect(s.somatic_signal).to eq(-1.0)
    end
  end

  describe '#positive_signal?' do
    it 'returns true for signal > 0.2' do
      expect(step.positive_signal?).to be true
    end

    it 'returns false for low signal' do
      s = described_class.new(index: 0, action: :x, expected_state: {}, somatic_signal: 0.1)
      expect(s.positive_signal?).to be false
    end
  end

  describe '#negative_signal?' do
    it 'returns true for signal < -0.2' do
      s = described_class.new(index: 0, action: :x, expected_state: {}, somatic_signal: -0.5)
      expect(s.negative_signal?).to be true
    end

    it 'returns false for neutral signal' do
      expect(step.negative_signal?).to be false
    end
  end

  describe '#high_confidence?' do
    it 'returns true at 0.7' do
      expect(step.high_confidence?).to be true
    end

    it 'returns false below 0.7' do
      s = described_class.new(index: 0, action: :x, expected_state: {}, confidence: 0.5)
      expect(s.high_confidence?).to be false
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = step.to_h
      expect(h).to include(:index, :action, :expected_state, :confidence, :somatic_signal)
    end
  end
end
