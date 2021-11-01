# frozen_string_literal: true

require 'active_support/concern'

module SnFoil
  module Deserializer
    module Base
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :snfoil_attribute_fields, :snfoil_attribute_transforms

        def attributes(*fields)
          @snfoil_attribute_fields ||= []
          @snfoil_attribute_fields |= fields
        end

        def attribute(key, **options)
          @snfoil_attribute_transforms ||= {}
          @snfoil_attribute_transforms[key] = options.merge(transform_type: :attribute)
        end

        def belongs_to(key, deserializer:, **options)
          @snfoil_attribute_transforms ||= {}
          @snfoil_attribute_transforms[key] = options.merge(deserializer: deserializer, transform_type: :has_one)
        end
        alias_method :has_one, :belongs_to

        def has_many(key, deserializer:, **options) # rubocop:disable Naming/PredicateName
          @snfoil_attribute_transforms ||= {}
          @snfoil_attribute_transforms[key] = options.merge(deserializer: deserializer, transform_type: :has_many)
        end

        def inherited(subclass)
          super

          instance_variables.grep(/@snfoil_.+/).each do |i|
            subclass.instance_variable_set(i, instance_variable_get(i).dup)
          end
        end
      end

      attr_reader :object, :options

      def initialize(object, **options)
        @object = object
        @options = options
      end

      def attributes
        @attributes ||=
          (self.class.snfoil_attribute_fields || []) | (self.class.snfoil_attribute_transforms || {}).map { |k, v| v[:key] || k }
      end

      def parse
        raise '#parse not implemented'
      end

      def to_hash
        parse
      end

      alias to_h to_hash
    end
  end
end
