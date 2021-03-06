require "set"
module Dry::Initializer
  # Rebuilds the initializer every time a new argument defined
  #
  # @api private
  #
  class Builder
    include Plugins

    def initialize
      @signature = Signature.new
      @plugins   = Set.new [VariableSetter, TypeConstraint, DefaultProc]
      @parts     = []
    end

    # Register new plugin to be applied as a chunk of code, or a proc
    # to be evaluated in the instance's scope
    #
    # @param [Dry::Initializer::Plugin]
    #
    # @return [Dry::Initializer::Builder]
    #
    def register(plugin)
      plugins = @plugins + [plugin]
      copy { @plugins = plugins }
    end

    # Makes builder to provide options-tolerant initializer
    #
    # @return [Dry::Initializer::Builder]
    #
    def tolerant_to_unknown_options
      copy { @tolerant = "**" }
    end

    # Makes builder to provide options-intolerant initializer
    #
    # @return [Dry::Initializer::Builder]
    #
    def intolerant_to_unknown_options
      copy { @tolerant = nil }
    end

    # Defines new agrument and reloads mixin definitions
    #
    # @param [#to_sym] name
    # @param [Hash<Symbol, Object>] settings
    #
    # @return [Dry::Initializer::Builder]
    #
    def define(name, settings)
      signature = @signature.add(name, settings)
      parts     = @parts + @plugins.map { |p| p.call(name, settings) }.compact

      copy do
        @signature = signature
        @parts     = parts
      end
    end

    # Redeclares initializer and readers in the mixin module
    #
    # @param [Module] mixin
    #
    def call(mixin)
      define_readers(mixin)
      reload_initializer(mixin)
      reload_callback(mixin)
      mixin
    end

    private

    def copy(&block)
      dup.tap { |instance| instance.instance_eval(&block) }
    end

    def define_readers(mixin)
      readers = @signature.select { |item| item.settings[:reader] != false }
                          .map(&:name)

      mixin.send :attr_reader, *readers if readers.any?
    end

    def reload_initializer(mixin)
      strings   = @parts.select { |part| String === part }
      signature = [@signature.call, @tolerant].map(&:to_s)
                                              .reject(&:empty?)
                                              .join(", ")
      mixin.class_eval <<-RUBY
        def initialize(#{signature})
          #{strings.join("\n")}
          __after_initialize__
        end
      RUBY
    end

    def reload_callback(mixin)
      blocks = @parts.select { |part| Proc === part }

      mixin.send :define_method, :__after_initialize__ do
        blocks.each { |block| instance_eval(&block) }
      end

      mixin.send :private, :__after_initialize__
    end
  end
end
