# frozen_string_literal: true

require 'active_support/concern'
require_relative 'base'

module SnFoil
  module Deserializer
    module JSONAPI
      extend ActiveSupport::Concern

      included do
        include SnFoil::Deserializer::Base

        module_eval do
          def parse
            if object[:data].is_a? Array
              object[:data].map { |d| build_attributes(d) }
            else
              build_attributes(object[:data])
            end
          end
        end
      end

      def included
        @included ||= options[:included] || object[:included]
      end

      private

      def build_attributes(data)
        attributes = data_id({}, data)
        attributes = parse_standard_attributes(attributes, data) if data[:attributes]
        attribute_transforms.each do |key, opts|
          attributes = apply_attribute_transform(attributes, data, key, **opts)
        end
        attributes
      end

      def data_id(attributes, data)
        if data[:id]
          attributes[:id] = data[:id]
        elsif data[:'local:id']
          attributes[:lid] = data[:'local:id']
        end
        attributes
      end

      def parse_standard_attributes(attributes, data)
        attributes.merge!(data[:attributes].select { |k, _| attribute_fields.include? k })
      end

      def apply_attribute_transform(attributes, data, key, transform_type:, **opts)
        case transform_type
        when :attribute
          parse_attribute_transform(attributes, data, key, **opts)
        when :has_one
          parse_has_one_relationship(attributes, data, key, **opts)
        when :has_many
          parse_has_many_relationship(attributes, data, key, **opts)
        end
      end

      def parse_attribute_transform(attributes, data, key, **opts)
        return attributes unless data.dig(:attributes, key)

        attributes.merge({ opts.fetch(:key) { key } => data[:attributes][key] })
      end

      def parse_relationships(attributes, data)
        self.class.has_one_relationships.each do |key, opts|
          attributes = has_one_relationship(attributes, data, key, **opts)
        end
        self.class.has_many_relationships.each do |key, opts|
          attributes = has_many_relationship(attributes, data, key, **opts)
        end
        attributes
      end

      def parse_has_one_relationship(attributes, data, key, deserializer:, **opts)
        resource_data = data.dig(:relationships, key, :data)
        return attributes unless resource_data

        resource_data = data_id(resource_data, resource_data)
        attribute_data = lookup_relationship(resource_data)
        relationship_data = { data: attribute_data || resource_data }
        attributes[opts.fetch(:key) { key }] = deserializer.new(relationship_data, **options, included: included).parse
        attributes
      end

      def parse_has_many_relationship(attributes, data, key, deserializer:, **opts)
        array_data = data.dig(:relationships, key, :data)
        return attributes unless array_data

        attributes[opts.fetch(:key) { key }] = array_data.map do |resource_data|
          resource_data = data_id(resource_data, resource_data)
          attribute_data = lookup_relationship(resource_data)
          relationship_data = { data: attribute_data || resource_data }
          deserializer.new(relationship_data, **options, included: included).parse
        end
        attributes
      end

      def lookup_relationship(type:, id: nil, lid: nil, **_opts)
        check_for_id(id, lid)

        included&.find do |x|
          x[:type].eql?(type) &&
            if id
              x[:id].eql?(id)
            elsif lid
              x[:'local:id'].eql?(lid)
            end
        end
      end

      def check_for_id(id, lid)
        raise ::ArgumentError, "missing keyword: id or lid for type: #{type}" unless id || lid
      end
    end
  end
end
