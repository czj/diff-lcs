# frozen_string_literal: true

require "test_helper"

require "diff/lcs/hunk"

class TestHunk < Minitest::Test
  def setup
    @old_data = ["Tu a un carté avec {count} itéms".encode("UTF-16LE")]
    @new_data = ["Tu a un carte avec {count} items".encode("UTF-16LE")]
    @pieces = diff(@old_data, @new_data)
    @hunk = hunk(@old_data, @new_data, @pieces[0], 3, 0)
  end

  def test_produces_a_unified_diff_from_the_two_pieces
    expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        @@ -1 +1 @@
        -Tu a un carté avec {count} itéms
        +Tu a un carte avec {count} items
    EXPECTED

    assert_equal expected, @hunk.diff(:unified)
  end

  def test_produces_a_unified_diff_from_the_two_pieces_last_entry
    expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        @@ -1 +1 @@
        -Tu a un carté avec {count} itéms
        +Tu a un carte avec {count} items
        \\ No newline at end of file
    EXPECTED

    assert_equal expected, @hunk.diff(:unified, true)
  end

  def test_produces_a_context_diff_from_the_two_pieces
    expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        ***************
        *** 1 ****
        ! Tu a un carté avec {count} itéms
        --- 1 ----
        ! Tu a un carte avec {count} items
    EXPECTED

    assert_equal expected, @hunk.diff(:context)
  end

  def test_produces_an_old_diff_from_the_two_pieces
    expected = <<-EXPECTED.gsub(/^ +/, "").encode("UTF-16LE").chomp
        1c1
        < Tu a un carté avec {count} itéms
        ---
        > Tu a un carte avec {count} items

    EXPECTED

    assert_equal expected, @hunk.diff(:old)
  end

  def test_with_empty_first_data_set_produces_a_unified_diff
    old_data = []
    pieces = diff(old_data, @new_data)
    hunk = hunk(old_data, @new_data, pieces[0], 3, 0)

    expected = <<-EXPECTED.gsub(/^\s+/, "").encode("UTF-16LE").chomp
        @@ -0,0 +1 @@
        +Tu a un carte avec {count} items
    EXPECTED

    assert_equal expected, hunk.diff(:unified)
  end

  def test_from_diff_without_differences
    assert_empty Diff::LCS::Hunk.from_diff(numbered_lines, numbered_lines, 3)
  end

  def test_from_diff_without_context_has_one_hunk_per_difference
    hunks = Diff::LCS::Hunk.from_diff(numbered_lines, changed_numbered_lines)

    assert_equal 3, hunks.size
    assert_equal [1, 1, 1], hunks.map { _1.blocks.size }
  end

  def test_from_diff_merges_hunks_that_overlap_because_of_context
    hunks = Diff::LCS::Hunk.from_diff(numbered_lines, changed_numbered_lines, 3)

    assert_equal 2, hunks.size
    assert_equal [2, 1], hunks.map { _1.blocks.size }
    assert_equal [[0, 9], [16, 19]], hunks.map { [_1.start_old, _1.end_old] }
    assert_equal [[0, 9], [16, 20]], hunks.map { [_1.start_new, _1.end_new] }
  end

  def test_diff_without_differences
    %i[old unified context].each do |format|
      assert_equal "", Diff::LCS::Hunk.diff(numbered_lines, numbered_lines, format, 3)
    end
  end

  def test_diff_old
    expected = <<~EXPECTED
      3c3
      < 3
      ---
      > three
      7c7
      < 7
      ---
      > seven
      19a20
      > nineteen and a half
    EXPECTED

    assert_equal expected, Diff::LCS::Hunk.diff(numbered_lines, changed_numbered_lines)
  end

  def test_diff_unified
    expected = <<~EXPECTED
      @@ -1,10 +1,10 @@
       1
       2
      -3
      +three
       4
       5
       6
      -7
      +seven
       8
       9
       10
      @@ -17,4 +17,5 @@
       17
       18
       19
      +nineteen and a half
       20
    EXPECTED

    assert_equal expected, Diff::LCS::Hunk.diff(numbered_lines, changed_numbered_lines, :unified, 3)
  end

  def test_diff_context
    expected = <<~EXPECTED
      ***************
      *** 1,10 ****
        1
        2
      ! 3
        4
        5
        6
      ! 7
        8
        9
        10
      --- 1,10 ----
        1
        2
      ! three
        4
        5
        6
      ! seven
        8
        9
        10
      ***************
      *** 17,20 ****
      --- 17,21 ----
        17
        18
        19
      + nineteen and a half
        20
    EXPECTED

    assert_equal expected, Diff::LCS::Hunk.diff(numbered_lines, changed_numbered_lines, :context, 3)
  end

  def test_diff_missing_newline_at_end_of_file
    expected = <<~EXPECTED
      @@ -1,2 +1,2 @@
       a
      -b
      +c
      \\ No newline at end of file
    EXPECTED

    assert_equal expected, Diff::LCS::Hunk.diff(["a\n", "b\n"], ["a\n", "c"], :unified, 3)
  end

  def test_diff_preserves_data_encoding
    expected = <<~EXPECTED.encode("UTF-16LE")
      @@ -1 +1 @@
      -Tu a un carté avec {count} itéms
      +Tu a un carte avec {count} items
      \\ No newline at end of file
    EXPECTED

    assert_equal expected, Diff::LCS::Hunk.diff(@old_data, @new_data, :unified, 3)
  end

  def test_diff_unknown_format
    assert_raises_with_message(RuntimeError, "Unknown diff format html.") do
      Diff::LCS::Hunk.diff(numbered_lines, changed_numbered_lines, :html)
    end
  end

  private

  def numbered_lines = (1..20).map { "#{_1}\n" }

  def changed_numbered_lines
    numbered_lines.tap do
      _1[2] = "three\n"
      _1[6] = "seven\n"
      _1.insert(19, "nineteen and a half\n")
    end
  end
end
