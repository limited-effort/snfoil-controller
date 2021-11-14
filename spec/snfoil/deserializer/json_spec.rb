# frozen_string_literal: true

require 'spec_helper'

require 'snfoil/deserializer/json'

RSpec.describe SnFoil::Deserializer::JSON do
  subject(:deserializer) { TestJsonDeserializer }

  let(:request) do
    JSON.parse(File.read('spec/fixtures/deserialize_json.json'))
  end

  describe '#parse' do
    let(:parsed_value) { deserializer.new(request).parse }

    it 'includes standard attributes' do
      expect(parsed_value[:name]).to eq('Test Form')
    end

    it 'does not parse a value twice' do
      expect(parsed_value.keys.count { |x| x == :name }).to be 1
    end
    
    it 'properly finds prefixed values' do
      expect(parsed_value[:interesting]).to eq('tetris')
    end

    # it 'sets the id of the object' do
    #   expect(parsed_value[:lid]).to eq('b9037e4a-ba86-4e0d-960c-c793baeee678')
    # end

    # it 'includes :attributes values' do
    #   expect(parsed_value[:name]).to eq('Test Form')
    # end

    # it 'includes any attribute transforms' do
    #   expect(parsed_value[:transformed]).to eq('z-o-r-p')
    # end

    # context 'when there is are has_one relationships' do
    #   it 'uses the supplied key in the relationship options' do
    #     expect(parsed_value[:author][:lid]).to eq('a4217889-4997-456c-99ce-cda87a1b5448')
    #   end

    #   it 'parses the attributes when the relationship is available in the includes' do
    #     expect(parsed_value[:author][:name]).to eq('harold')
    #   end

    #   it 'parses the id when the relationship is not available in the includes' do
    #     expect(parsed_value[:owner][:id]).to eq('1')
    #   end
    # end

    # context 'when there is a has_many relationships' do
    #   it 'uses the supplied key in the relationship options' do
    #     expect(parsed_value[:envs].count).to eq(2)
    #   end

    #   it 'parses the attributes when the relationship is available in the includes' do
    #     expect(parsed_value[:versions][0][:name]).to eq('initial-commit')
    #   end

    #   it 'parses the id when the relationship is not available in the includes' do
    #     expect(parsed_value[:envs][0][:id]).to eq('1')
    #   end
    # end
  end
end

class MiscJsonDeserializer
  include SnFoil::Deserializer::JSON

  attributes :name
end

class TestJsonDeserializer
  include SnFoil::Deserializer::JSON

  attributes :name, :description, :id
  attributes :name
  attribute :id
  attribute :lid, key: 'local:id'
  attribute :interesting, prefix: :prefixed_

  attribute :other
  attribute(:odd, key: :transformed)

  has_one(:author, key: :target, deserializer: MiscJsonDeserializer)
  has_one(:owner, deserializer: MiscJsonDeserializer)
  has_many(:environments, key: :envs, deserializer: MiscJsonDeserializer)
  has_many(:versions, deserializer: MiscJsonDeserializer)
end
