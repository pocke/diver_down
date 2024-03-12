# frozen_string_literal: true

require 'securerandom'

module Diverdown
  class Definition
    require 'diverdown/definition/source'
    require 'diverdown/definition/dependency'
    require 'diverdown/definition/modulee'
    require 'diverdown/definition/method_id'
    require 'diverdown/definition/to_dot'

    # @param hash [Hash]
    # @return [Diverdown::Definition]
    def self.from_hash(hash)
      new(
        id: hash[:id] || SecureRandom.uuid,
        title: hash[:title] || '',
        sources: (hash[:sources] || []).map do |source_hash|
          Diverdown::Definition::Source.from_hash(source_hash)
        end
      )
    end

    attr_reader :id, :title, :parent, :children

    # @param title [String]
    # @param sources [Array<Diverdown::Definition::Source>]
    def initialize(id: SecureRandom.hex, title: '', sources: [], parent: nil, children: [])
      @id = id.gsub(/\s+/, '+')
      @title = title
      @source_map = sources.map { [_1.source, _1] }.to_h
      @parent = parent
      @children = children.to_set
    end

    # @param source [String]
    # @return [Diverdown::Definition::Source]
    def source(source)
      @source_map[source] ||= Diverdown::Definition::Source.new(source:)
    end

    # @return [Array<Diverdown::Definition::Source>]
    def sources
      @source_map.values.sort
    end

    # @param parent [Diverdown::Definition]
    def parent=(parent)
      @parent = parent
      parent.children << self
    end

    # This definition is top level
    # @return [Boolean]
    def top?
      parent.nil?
    end

    # @return [Integer]
    def level
      return 0 if top?

      parent.level + 1
    end

    # @return [String]
    def to_dot
      Diverdown::Definition::ToDot.new(self).to_s
    end

    # @return [String]
    def to_h
      {
        id:,
        title:,
        sources: sources.map(&:to_h),
      }
    end

    # Combine two definitions into one
    # @param other_definition [Diverdown::Definition]
    # @return [self]
    def combine(other_definition)
      new_sources = (sources + other_definition.sources).group_by(&:source).map do |_, same_sources|
        last_source = same_sources.pop
        same_sources.inject(last_source) do |source, other_source|
          source.combine(other_source)
        end
      end

      @source_map = new_sources.map { [_1.source, _1] }.to_h

      self
    end

    # @param other [Object, Diverdown::Definition::Source]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        id == other.id &&
        sources.sort == other.sources.sort &&
        parent == other.parent &&
        children == other.children
    end
    alias eq? ==
    alias eql? ==

    # @return [Integer]
    def hash
      [self.class, id, sources].hash
    end
  end
end
