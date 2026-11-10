# frozen_string_literal: true

module Diff; end unless defined? Diff
module Diff::LCS; end unless defined? Diff::LCS

# The Data API (keyword or positional construction, +members+, +to_h+, +with+, +eql?+,
# +hash+, frozen instances) for Diff::LCS::Change and Diff::LCS::ContextChange. They are
# built for each element of a traversal, and a Data subclass validating in +initialize+
# allocates three more objects per instance than a plain class (ruby-core#22437).
#
# An including class defines +members+, +values+, readers, and an +initialize+ taking
# each member positionally with NO_ARGUMENT as default, which calls
# +arguments_to_members+ when its last member is NO_ARGUMENT, then freezes.
module Diff::LCS::FrozenValue # :nodoc:
  NO_ARGUMENT = Object.new.freeze

  def self.included(base)
    base.singleton_class.alias_method :[], :new
  end

  def members = self.class.members

  def to_h(&) = members.zip(values).to_h(&)

  def with(**changes)
    return self if changes.empty?
    # The keyword constructor raises the same unknown keyword error as Data.
    return self.class.new(**to_h.merge!(changes)) unless changes.each_key.all? { members.include?(_1) }

    values = self.values
    changes.each { |member, value| values[members.index(member)] = value }
    self.class.new(*values)
  end

  def eql?(other) = self.class == other.class && values.eql?(other.values)

  def hash = [self.class, values].hash

  def inspect = "#<#{self.class} #{members.zip(values).map { |member, value| "#{member}=#{value.inspect}" }.join(", ")}>"

  alias_method :to_s, :inspect

  def marshal_dump = values

  # YAML loads the members through +initialize+ too, so loaded values are validated and frozen.
  def encode_with(coder) = members.zip(values) { |member, value| coder[member.to_s] = value }

  def init_with(coder) = initialize(*coder.map.values_at(*members.map(&:to_s)))

  private

  # Unlike Data, +allocate+ stays defined: TruffleRuby's Marshal calls it before
  # +marshal_load+.
  def marshal_load(values) = initialize(*values)

  def initialize_copy(*) = super.freeze

  def arguments_to_members(*arguments)
    arguments = arguments.take_while { !NO_ARGUMENT.equal?(_1) }
    keywords =
      if arguments.size == 1 && arguments.first.is_a?(Hash)
        arguments.first
      else
        members.first(arguments.size).zip(arguments).to_h
      end

    missing = members - keywords.keys
    raise ArgumentError, "missing keyword#{"s" if missing.size > 1}: #{missing.map(&:inspect).join(", ")}" if missing.any?

    unknown = keywords.keys - members
    raise ArgumentError, "unknown keyword#{"s" if unknown.size > 1}: #{unknown.map(&:inspect).join(", ")}" if unknown.any?

    keywords.values_at(*members)
  end
end
