# frozen_string_literal: true

require 'active_support/concern'

module SnFoil
  module Deserializer
    module JSON
      extend ActiveSupport::Concern

      class << self
        attr_reader :i_attribute_fields

        def attributes(*fields, **options)
          @i_attribute_fields ||= []
          prefix = options.fetch(:prefix, nil)

          @i_attribute_fields |= fields.map { |field| { attribute_name: field, param_name: "#{prefix}#{field}" } }
        end

        def attribute(field, **options)
          @i_attribute_fields ||= []
          param_name = options.fetch(:param, nil)
          prefix = options.fetch(:prefix, nil)

          @i_attribute_fields |= if param_name
                                   [{ attribute_name: field, param_name: param_name }]
                                 else
                                   [{ attribute_name: field, param_name: "#{prefix}#{field}" }]
                                 end
        end

        def parse(params)
          data = {}

          @i_attribute_fields.each do |field_config|
            next unless params.key?(field_config[:param_name])

            data[field_config[:attribute_name]] = params[field_config[:param_name]]
          end

          data
        end
      end
    end
  end
end
