# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnFoil::Deserializer::JSONAPI do
  subject(:deserializer) { TestDeserializer }

  let(:request) do
    JSON.parse(File.read('spec/fixtures/deserialize_jsonapi.json'))
  end

  describe '#self.attributes' do
    it 'assigns values to attributes class variable' do
      expect(TestDeserializer.new(request).attributes).to include(:name, :description)
    end

    it 'ignores repeat values' do
      name_count = TestDeserializer.new(request).attributes.count { |x| x == :name }
      expect(name_count).to eq 1
    end
  end

  describe '#self.attribute' do
    it 'adds the key to the attributes' do
      expect(TestDeserializer.new(request).attributes).to include(:other)
    end

    context 'with a key options' do
      it 'adds the key to the attributes' do
        expect(TestDeserializer.new(request).attributes).to include(:transformed)
      end
    end
  end

  describe '#self.has_one' do
    it 'adds the key to the attributes' do
      expect(TestDeserializer.new(request).attributes).to include(:versions)
    end

    context 'with a key options' do
      it 'adds the key to the attributes' do
        expect(TestDeserializer.new(request).attributes).to include(:envs)
      end
    end
  end

  describe '#self.has_many' do
    it 'adds the key to the attributes' do
      expect(TestDeserializer.new(request).attributes).to include(:versions)
    end
  end

  describe '#parse' do
    let(:parsed_value) { TestDeserializer.new(request).parse }

    it 'sets the id of the object' do
      expect(parsed_value[:lid]).to eq('b9037e4a-ba86-4e0d-960c-c793baeee678')
    end

    it 'includes :attributes values' do
      expect(parsed_value[:name]).to eq('Test Form')
    end

    it 'includes any attribute transforms' do
      expect(parsed_value[:transformed]).to eq('z-o-r-p')
    end

    context 'when there is are has_one relationships' do
      it 'uses the supplied key in the relationship options' do
        expect(parsed_value[:author][:lid]).to eq('a4217889-4997-456c-99ce-cda87a1b5448')
      end

      it 'parses the attributes when the relationship is available in the includes' do
        expect(parsed_value[:author][:name]).to eq('harold')
      end

      it 'parses the id when the relationship is not available in the includes' do
        expect(parsed_value[:owner][:id]).to eq('1')
      end
    end

    context 'when there is a has_many relationships' do
      it 'uses the supplied key in the relationship options' do
        expect(parsed_value[:envs].count).to eq(2)
      end

      it 'parses the attributes when the relationship is available in the includes' do
        expect(parsed_value[:versions][0][:name]).to eq('initial-commit')
      end

      it 'parses the id when the relationship is not available in the includes' do
        expect(parsed_value[:envs][0][:id]).to eq('1')
      end
    end
  end
end

class MiscDeserializer
  include SnFoil::Deserializer::JSONAPI

  attribute :name
end

class TestDeserializer
  include SnFoil::Deserializer::JSONAPI

  attributes :name, :description
  attributes :name

  attribute :other
  attribute(:odd, key: :transformed)

  has_one(:target, key: :author, deserializer: MiscDeserializer)
  has_one(:owner, deserializer: MiscDeserializer)
  has_many(:environments, key: :envs, deserializer: MiscDeserializer)
  has_many(:versions, deserializer: MiscDeserializer)
end
