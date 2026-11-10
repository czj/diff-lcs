# frozen_string_literal: true

require_relative "test_helper"

class TestGroupedSDiff < Minitest::Test
  def grouped_sdiff(s1, s2) = sdiff(s1, s2, Diff::LCS::GroupedSDiffCallbacks)

  def grouped_context_diff(result) = result.map { |group| context_diff(group) }

  def reverse_grouped_sdiff(result) = result.map { |group| reverse_sdiff(group) }

  def compare_sequences_correctly(s1, s2, result)
    assert_equal grouped_context_diff(result), grouped_sdiff(s1, s2)
    assert_equal grouped_context_diff(reverse_grouped_sdiff(result)), grouped_sdiff(s2, s1)
  end

  def test_seq1_seq2
    result = [
      [["-", [0, "a"], [0, nil]]],
      [["=", [1, "b"], [0, "b"]], ["=", [2, "c"], [1, "c"]]],
      [["+", [3, nil], [2, "d"]]],
      [["=", [3, "e"], [3, "e"]]],
      [["!", [4, "h"], [4, "f"]]],
      [["=", [5, "j"], [5, "j"]]],
      [["+", [6, nil], [6, "k"]]],
      [["=", [6, "l"], [7, "l"]], ["=", [7, "m"], [8, "m"]]],
      [["!", [8, "n"], [9, "r"]], ["!", [9, "p"], [10, "s"]]],
      [["+", [10, nil], [11, "t"]]]
    ]
    compare_sequences_correctly(seq1, seq2, result)
  end

  def test_a_e_vs_a_b_c_d_e
    s1 = %w[a e]
    s2 = %w[a b c d e]
    result = [
      [["=", [0, "a"], [0, "a"]]],
      [["+", [1, nil], [1, "b"]], ["+", [1, nil], [2, "c"]], ["+", [1, nil], [3, "d"]]],
      [["=", [1, "e"], [4, "e"]]]
    ]
    compare_sequences_correctly(s1, s2, result)
  end

  def test_a_b_c_vs_1
    s1 = %w[a b c]
    s2 = %w[1]
    result = [
      [["!", [0, "a"], [0, "1"]]],
      [["-", [1, "b"], [1, nil]], ["-", [2, "c"], [1, nil]]]
    ]
    compare_sequences_correctly(s1, s2, result)
  end

  def test_empty_vs_a_b_c
    s1 = %w[]
    s2 = %w[a b c]
    result = [
      [["+", [0, nil], [0, "a"]], ["+", [0, nil], [1, "b"]], ["+", [0, nil], [2, "c"]]]
    ]
    compare_sequences_correctly(s1, s2, result)
  end

  def test_identical_sequences
    s1 = %w[a b c]
    result = [
      [["=", [0, "a"], [0, "a"]], ["=", [1, "b"], [1, "b"]], ["=", [2, "c"], [2, "c"]]]
    ]
    compare_sequences_correctly(s1, s1, result)
  end

  def test_empty_vs_empty
    assert_empty grouped_sdiff([], [])
  end

  def test_string
    result = [
      [["=", [0, "a"], [0, "a"]]],
      [["!", [1, "b"], [1, "x"]]],
      [["+", [2, nil], [2, "y"]]],
      [["=", [2, "c"], [3, "c"]]]
    ]
    assert_equal grouped_context_diff(result), grouped_sdiff("abc", "axyc")
  end

  def test_groups_have_one_action_and_adjacent_groups_differ
    groups = grouped_sdiff(seq1, seq2)

    groups.each { |group| assert_equal 1, group.map(&:action).uniq.size }
    groups.each_cons(2) { |a, b| refute_equal a.first.action, b.first.action }
  end

  def test_flattened_groups_match_sdiff
    assert_equal sdiff(seq1, seq2), grouped_sdiff(seq1, seq2).flatten(1)
    assert_equal sdiff(seq2, seq1), grouped_sdiff(seq2, seq1).flatten(1)
  end

  def test_patch_and_unpatch
    groups = grouped_sdiff(seq1, seq2)

    assert_equal seq2, patch(seq1, groups)
    assert_equal seq1, unpatch!(seq2, groups)
  end

  def test_block_is_called_for_each_change
    result = sdiff(seq1, seq2, Diff::LCS::GroupedSDiffCallbacks) { _1.to_a }

    assert_equal sdiff(seq1, seq2).map(&:to_a), result.flatten(1)
  end

  def test_block_mode_finishes
    callbacks = Diff::LCS::GroupedSDiffCallbacks.new { traverse_balanced(seq1, seq2, _1) }

    assert_equal grouped_sdiff(seq1, seq2), callbacks.diffs
  end

  def test_last_group_requires_finish
    callbacks = Diff::LCS::GroupedSDiffCallbacks.new
    traverse_balanced(seq1, seq2, callbacks)

    assert_equal grouped_sdiff(seq1, seq2)[0..-2], callbacks.diffs

    callbacks.finish

    assert_equal grouped_sdiff(seq1, seq2), callbacks.diffs
  end
end
