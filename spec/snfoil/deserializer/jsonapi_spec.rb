# frozen_string_literal: true

require 'spec_helper'
require 'snfoil/deserializer/jsonapi'

RSpec.describe SnFoil::Deserializer::JSONAPI do
  subject(:deserializer) { TestJsonapiDeserializer }

  let(:request) do
    JSON.parse(File.read('spec/fixtures/deserialize_jsonapi.json'))
  end

  describe '#parse' do
    let(:parsed_value) { TestJsonapiDeserializer.new(request).parse }

    it 'sets the id of the object' do
      expect(parsed_value[:'local:id']).to eq('b9037e4a-ba86-4e0d-960c-c793baeee678')
    end

    it 'includes :attributes values' do
      expect(parsed_value[:name]).to eq('Test Form')
    end

    it 'includes any attribute transforms' do
      expect(parsed_value[:transformed]).to eq('z-o-r-p')
    end

    it 'properly finds prefixed values' do
      expect(parsed_value[:interesting]).to eq 'tetris'
    end

    context 'when there is are has_one relationships' do
      it 'uses the supplied key in the relationship options' do
        expect(parsed_value[:author][:'local:id']).to eq('a4217889-4997-456c-99ce-cda87a1b5448')
      end

      it 'parses the attributes when the relationship is available in the includes' do
        expect(parsed_value[:author][:name]).to eq('harold')
      end

      it 'parses the id when the relationship is not available in the includes' do
        expect(parsed_value[:owner][:id]).to eq('42')
      end
    end

    context 'when there is a has_many relationships' do
      it 'uses the supplied key in the relationship options' do
        expect(parsed_value[:environments].count).to eq(2)
      end

      it 'parses the attributes when the relationship is available in the includes' do
        expect(parsed_value[:versions][0][:name]).to eq('initial-commit')
      end

      it 'parses the id when the relationship is not available in the includes' do
        expect(parsed_value[:environments][0][:id]).to eq('1')
      end
    end
  end
end

class MiscJsonapiDeserializer
  include SnFoil::Deserializer::JSONAPI

  attribute :name
end

class TestJsonapiDeserializer
  include SnFoil::Deserializer::JSONAPI

  attributes :name, :description
  attributes :name

  attribute :other
  attribute :interesting, prefix: :prefixed_
  attribute :transformed, key: :odd

  belongs_to(:missing, deserializer: MiscJsonapiDeserializer)
  has_one(:author, key: :target, deserializer: MiscJsonapiDeserializer)
  has_one(:owner, deserializer: MiscJsonapiDeserializer)
  has_many(:environments, deserializer: MiscJsonapiDeserializer)
  has_many(:more_missing, deserializer: MiscJsonapiDeserializer)
  has_many(:versions, deserializer: MiscJsonapiDeserializer)
end
