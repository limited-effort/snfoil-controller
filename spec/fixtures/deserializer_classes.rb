# frozen_string_literal: true

class MiscDeserializer
  include SnFoil::Deserializer::JSONAPI

  attribute :name
end

class TestDeserializer
  include SnFoil::Deserializer::JSONAPI

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
