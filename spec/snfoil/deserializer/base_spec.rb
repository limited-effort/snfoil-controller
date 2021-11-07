# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnFoil::Deserializer::JSONAPI do
  subject(:deserializer) { TestDeserializer }

  let(:request) do
    JSON.parse(File.read('spec/fixtures/deserialize_jsonapi.json'))
  end

  describe '#self.attributes' do
    it 'assigns values to attributes class variable' do
      expect(deserializer.snfoil_attribute_fields).to include(:name, :description)
    end

    it 'ignores repeat values' do
      name_count = deserializer.snfoil_attribute_fields.count { |x| x == :name }
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
    let(:instance) { subject.new(request, foo: 'bar', fizz: 'bang') }

    # it 'assigns value to object' do
    #   expect(instance.object).to eq(request)
    # end

    # it 'assigns hash values to options' do
    #   expect(instance.options).to eq(foo: 'bar', fizz: 'bang')
    # end
  end

  describe '#parse' do
    it 'raises an error' do
      expect do
        deserializer.new(request).parse
      end.to raise_error RuntimeError
    end
  end
end

class MiscDeserializer
  include SnFoil::Deserializer::Base

  attribute :name
end

class TestDeserializer
  include SnFoil::Deserializer::Base

  key_transform :underscore

  attributes :name, :description, :two_words
  attributes :name

  attribute :other
  attribute(:odd, key: :transformed)

  has_one(:target, key: :author, deserializer: MiscDeserializer)
  has_one(:owner, deserializer: MiscDeserializer)
  has_many(:environments, key: :envs, deserializer: MiscDeserializer)
  has_many(:versions, deserializer: MiscDeserializer)
end
