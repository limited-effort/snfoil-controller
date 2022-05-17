# frozen_string_literal: true

require 'spec_helper'
require 'snfoil/deserializer/base'

RSpec.describe SnFoil::Deserializer::Base do
  subject(:deserializer) { TestBaseDeserializer.clone }

  let(:request) do
    JSON.parse(File.read('spec/fixtures/deserialize_jsonapi.json'))
  end

  describe '#self.attributes' do
    it 'assigns values to attributes class variable' do
      expect(deserializer.snfoil_attribute_transforms.keys).to include(:name, :description)
    end

    it 'ignores repeat values' do
      name_count = deserializer.snfoil_attribute_transforms.keys.count { |x| x == :name }
      expect(name_count).to eq 1
    end
  end

  describe '#self.attribute' do
    it 'adds the key to the attributes transforms' do
      expect(deserializer.snfoil_attribute_transforms.keys).to include(:other)
    end
  end

  describe '#self.has_one' do
    it 'adds the key to the attributes transforms' do
      expect(deserializer.snfoil_attribute_transforms.keys).to include(:versions)
    end
  end

  describe '#self.has_many' do
    it 'adds the key to the attributes' do
      expect(deserializer.snfoil_attribute_transforms.keys).to include(:versions)
    end
  end

  describe '#self.key_transform' do
    it 'sets the key transform' do
      expect(deserializer.snfoil_key_transform).to eq(:underscore)
    end
  end

  describe '#initialize' do
    let(:data) { deserializer.new(request).data }

    context 'with no key_transform set' do
      it 'defaults to :underscore' do
        expect(data[:data][:attributes][:two_word]).to eq 'keys'
      end

      it 'always to_syms the final product' do
        expect(data.keys).to include :data
        expect(data.keys).not_to include 'data'
      end
    end

    context 'when key_transform => any_inflector' do
      before do
        deserializer.key_transform :upcase
      end

      it 'always to_syms the final product' do
        expect(data.keys).to include :DATA
        expect(data.keys).not_to include :data
      end
    end

    context 'when key_transform => &block' do
      before do
        deserializer.key_transform { |k| "attr_#{k.upcase}" }
      end

      it 'uses the transform' do
        expect(data.keys).to include :attr_DATA
        expect(data.keys).not_to include :data
      end

      it 'always to_syms the final product' do
        expect(data.keys).to include :attr_DATA
        expect(data.keys).not_to include 'attr_DATA'
      end
    end
  end
end

class MiscBaseDeserializer
  include SnFoil::Deserializer::Base

  attribute :name
end

class TestBaseDeserializer
  include SnFoil::Deserializer::Base

  key_transform :underscore

  attributes :name, :description, :two_words
  attributes :name

  attribute :other
  attribute(:odd, key: :transformed)

  has_one(:target, key: :author, deserializer: MiscBaseDeserializer)
  has_one(:owner, deserializer: MiscBaseDeserializer)
  has_many(:environments, key: :envs, deserializer: MiscBaseDeserializer)
  has_many(:versions, deserializer: MiscBaseDeserializer)
end
