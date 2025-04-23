# frozen_string_literal: true

require 'spec_helper'
require 'json'

require 'snfoil/deserializer/json'

RSpec.describe SnFoil::Deserializer::JSON do
  subject(:deserializer) { TestJsonDeserializer }

  let(:config) { { value: true } }

  let(:request) do
    JSON.parse(File.read('spec/fixtures/deserialize_json.json'))
  end

  describe '#parse' do
    let(:parsed_value) { deserializer.new(request, **config).parse }

    it 'includes standard attributes' do
      expect(parsed_value[:name]).to eq 'Test Form'
    end

    it 'does not parse a value twice' do
      expect(parsed_value.keys.count { |x| x == :name }).to be 1
    end

    it 'properly finds prefixed values' do
      expect(parsed_value[:interesting]).to eq 'tetris'
    end

    it 'properly finds namespaced values' do
      expect(parsed_value[:treasure]).to eq 'gold'
    end

    it 'uses options[:key] to find a value' do
      expect(parsed_value[:lid]).to eq 'b9037e4a-ba86-4e0d-960c-c793baeee678'
    end

    it 'uses blocks when present' do
      expect(parsed_value[:blocky]).to eq 'other test form'
    end

    it 'uses methods when present' do
      expect(parsed_value[:methody]).to eq 'method_keys'
    end

    it 'finds has_many relationships' do
      expect(parsed_value[:environments].count).to eq 2
    end

    it 'finds has_one relationships' do
      expect(parsed_value[:owner][:id]).to eq '42'
    end

    it 'finds belongs_to relationships' do
      expect(parsed_value[:author][:lid]).to eq 'a4217889-4997-456c-99ce-cda87a1b5448'
    end

    context 'when an attribute is defined but not present' do
      it 'leaves that value out' do
        expect(parsed_value.keys).not_to include(:missing)
      end
    end

    context 'when an attirbute has a conditional :if' do
      context 'when the conditional is truthy' do
        it 'renders the attribute when the conditional is true' do
          expect(parsed_value[:passing_relationship][:lid]).to eq 'a4217889-4997-456c-99ce-cda87a1b5448'
        end
      end

      context 'when the conditional is false' do
        let(:config) { { value: false } }

        it 'does not render the attribute' do
          expect(parsed_value.keys).not_to include(:passing_relationship)
        end
      end
    end

    context 'when an attirbute has a conditional :unless' do
      context 'when the conditional is truthy' do
        it 'renders the attribute when the conditional is true' do
          expect(parsed_value.keys).not_to include(:failing_relationship)
        end
      end

      context 'when the conditional is false' do
        let(:config) { { value: false } }

        it 'does not render the attribute' do
          expect(parsed_value[:failing_relationship][:lid]).to eq 'a4217889-4997-456c-99ce-cda87a1b5448'
        end
      end
    end
  end
end

class MiscJsonDeserializer
  include SnFoil::Deserializer::JSON

  attributes :name, :id
  attribute :lid, key: 'local:id'
end

class TestJsonDeserializer
  include SnFoil::Deserializer::JSON

  attributes :name, :description, :id
  attributes :name
  attribute :id
  attribute :lid, key: 'local:id'
  attribute :interesting, prefix: :prefixed_
  attribute :treasure, namespace: %i[deep namespaced]

  attribute :other
  attribute(:odd, key: :transformed)
  attribute(:blocky) { |input, _key| "#{input[:other]} #{input[:name].downcase}" }
  attribute(:methody, with: :method_check)

  belongs_to(:missing, deserializer: MiscJsonDeserializer)
  belongs_to(:author, key: :target, deserializer: MiscJsonDeserializer)
  belongs_to(:passing_relationship, key: :target, if: ->(_) { config[:value] }, deserializer: MiscJsonDeserializer)
  belongs_to(:failing_relationship, key: :target, unless: ->(_) { config[:value] }, deserializer: MiscJsonDeserializer)
  has_one(:owner, deserializer: MiscJsonDeserializer)
  has_many(:environments, key: :envs, deserializer: MiscJsonDeserializer)
  has_many(:versions, deserializer: MiscJsonDeserializer)

  def method_check(input, _, **_)
    "method_#{input[:two_word]}"
  end
end
