# frozen_string_literal: true

require_relative "test_helper"

class TestLCSInternals < Minitest::Test
  def test_returns_meaningful_lcs_array_with_seq1_seq2
    res = internal_lcs(seq1, seq2)
    assert_equal correct_lcs.size, res.compact.size
    assert_correctly_maps_sequence(res, seq1, seq2)

    x_seq1 = (0...res.size).map { |ix| res[ix] ? seq1[ix] : nil }.compact
    x_seq2 = (0...res.size).map { |ix| res[ix] ? seq2[res[ix]] : nil }.compact

    assert_equal correct_lcs, x_seq1
    assert_equal correct_lcs, x_seq2
  end

  def test_returns_all_indexes_with_hello_hello
    assert_equal (0...hello.size).to_a, internal_lcs(hello, hello)
  end

  def test_returns_all_indexes_with_hello_ary_hello_ary
    assert_equal (0...hello_ary.size).to_a, internal_lcs(hello_ary, hello_ary)
  end

  def test_maps_strings_like_their_characters
    assert_equal internal_lcs("abcabba", "cbabac"), internal_lcs("abcabba".chars, "cbabac".chars)
  end

  def test_finds_a_longest_common_subsequence_among_repeated_elements
    random = Random.new(20261103)

    500.times do
      alphabet_size = [1, 2, 3, 5].sample(random:)
      s1 = Array.new(random.rand(0..30)) { random.rand(alphabet_size) }
      s2 = Array.new(random.rand(0..30)) { random.rand(alphabet_size) }
      res = internal_lcs(s1, s2)

      assert_correctly_maps_sequence(res, s1, s2)
      assert_equal res.compact, res.compact.sort.uniq
      assert_equal dynamic_programming_lcs_size(s1, s2), res.compact.size
    end
  end

  private def dynamic_programming_lcs_size(s1, s2)
    previous_row = Array.new(s2.size + 1, 0)
    s1.each do |element|
      row = [0]
      s2.each_with_index do |other, index|
        row << ((element == other) ? previous_row[index] + 1 : [previous_row[index + 1], row[index]].max)
      end
      previous_row = row
    end
    previous_row.last
  end
end

class TestLCS < Minitest::Test
  def test_returns_correct_compacted_values
    res = lcs(seq1, seq2)
    assert_equal correct_lcs, res
    assert_equal res, res.compact
  end

  def test_is_transitive
    res = lcs(seq2, seq1)
    assert_equal correct_lcs, res
    assert_equal res, res.compact
  end

  def test_returns_hello_chars_with_hello_hello
    assert_equal hello.chars, lcs(hello, hello)
  end

  def test_returns_hello_ary_with_hello_ary_hello_ary
    assert_equal hello_ary, lcs(hello_ary, hello_ary)
  end
end
