# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnFoil::Controller do
  subject(:including_class) { Class.new ControllerSpecClass }

  let(:canary) { Canary.new }

  describe '#self.context' do
    let(:context) { double }

    before { including_class.context(context) }

    it 'sets snfoil_context' do
      expect(including_class.snfoil_context).to eq context
    end
  end

  describe '#self.serializer' do
    let(:serializer) { double }

    before { including_class.serializer(serializer) }

    it 'sets snfoil_serializer' do
      expect(including_class.snfoil_serializer).to eq serializer
    end
  end

  describe '#self.deserializer' do
    let(:deserializer) { double }

    it 'sets snfoil_deserializer' do
      including_class.deserializer(deserializer)
      expect(including_class.snfoil_deserializer).to eq deserializer
    end

    context 'when called with a block' do
      let(:deserializer_block) { proc {} }

      it 'sets snfoil_deserializer' do
        including_class.deserializer(deserializer, &deserializer_block)
        expect(including_class.snfoil_deserializer_block).to eq deserializer_block
      end
    end
  end

  describe '#self.endpoint' do
    it 'creates setup_#{name} hooks' do # rubocop:disable Lint/InterpolationCheck
      including_class.endpoint(:demo, with: :render_demo)
      expect(including_class.respond_to?(:setup_demo)).to be true
    end

    it 'creates process_#{name} hooks' do # rubocop:disable Lint/InterpolationCheck
      including_class.endpoint(:demo, with: :render_demo)
      expect(including_class.respond_to?(:process_demo)).to be true
    end

    it 'defines an instance method' do
      including_class.endpoint(:demo, with: :render_demo)
      expect(including_class.new.respond_to?(:demo)).to be true
    end

    context 'when called with a method' do
      it 'calls the method on the instance call' do
        including_class.endpoint(:demo, with: :render_demo)
        including_class.define_method(:render_demo) { |**options| options[:canary].sing('Method Call') }
        including_class.new.demo(canary: canary)

        expect(canary.sung?('Method Call')).to be true
      end
    end

    context 'when called with a block' do
      it 'calls the block on the instance call' do
        including_class.endpoint(:demo) { |**options| options[:canary].sing('Block Call') }
        including_class.new.demo(canary: canary)

        expect(canary.sung?('Block Call')).to be true
      end
    end

    describe '#entity' do
      context 'when current_entity is defined' do
        before { including_class.define_method(:current_entity) { 'entity' } }

        it 'uses it' do
          expect(including_class.new.entity).to eq 'entity'
        end
      end

      context 'when current_user is defined' do
        before { including_class.define_method(:current_user) { 'user' } }

        it 'uses it' do
          expect(including_class.new.entity).to eq 'user'
        end
      end
    end

    describe '#serialize' do
      context 'when a serializer is configured' do
        let(:object) { double }
        let(:serializer) { double }
        let(:serializer_instance) { double }

        before do
          allow(serializer).to receive(:new).and_return(serializer_instance)
          allow(serializer_instance).to receive(:to_hash).and_return({})
        end

        it 'calls the serializer and uses the default call' do
          including_class.serializer serializer
          including_class.new.serialize(object)
          expect(serializer).to have_received(:new).with(object, anything)
          expect(serializer_instance).to have_received :to_hash
        end

        context 'when a block is configured' do
          before do
            including_class.serializer(serializer) do |object, serializer, **options|
              options[:canary].sing({ object: object, serializer: serializer, m: '1' })
            end
          end

          it 'uses the block to process the call' do
            including_class.new.serialize(object, canary: canary)
            expect(serializer).not_to have_received(:new)
            expect(canary.song[0][:data]).to eq({ object: object, serializer: serializer, m: '1' })
          end
        end

        context 'when a block is passed in the options' do
        end
      end

      context 'when a serializer is not configured' do
      end

      context 'when a serializer is in the options' do
      end
    end
  end
end

class ControllerSpecClass
  include SnFoil::Controller
end
