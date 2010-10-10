=begin
This implement the ability to insert an object who already exists in a Tree
 by duplicating every child added

It looks more like a Tree mad eof nodes containing contents,
 but it still allow very handy comparaison(if dup doesn't look at object_id)

You need to get the dupped result object every time anyway to use it
=end
require_relative '../tree'

module TreeNode
  # speed improvement
  remove_method :parent=
  protected
  def parent= p
    @_node_parent = p
    p.children << self
  end
  public

  remove_method :<<
  def << child
    case child
    when TreeNode
      # Old way, 3 times slower
      # if all.find { |o| o.object_id == child.object_id }
      #   child = child.dup.extend(TreeNode)
      # end
      child.parent = self
      # @_node_children << child
      child
    when Array
      child.map { |c| self << c }
    else
      self << child.dup.extend(TreeNode) # New way, dup every child
    end
  end
end

if __FILE__ == $0
  require "minitest/autorun"
  class TestTree < MiniTest::Unit::TestCase
    def c(actual, expected)
      assert_equal(expected, actual)
    end

    def setup
      @c1, @c11, @c111, @c1111, @c1112, @c12, @c2, @c21 =
      %w[c1 c11 c111 c1111 c1112 c12 c2 c21]
      @root = @t = "root".extend(TreeNode)
      @c1 = @t << @c1
      @c11 = @c1 << @c11
      @c21 = (@c2 = @t << @c2) << @c21
      @c1 << @c12
      @c1111, @c1112 = (@c111 = @t[0][0] << @c111) << [@c1111, @c1112]
      #puts @t.show_simple
      #puts @t.show
    end

    def test_basic
      c @t.root, @root

      c @c1.descendants, [@c11, @c111, @c1111, @c1112, @c12]
      c @c1.descendants_with_self, [@c1, @c11, @c111, @c1111, @c1112, @c12]

      c @c111.ascendants, [@c11, @c1, @root]
      c @c111.ascendants_with_self, [@c111, @c11, @c1, @root]

      c @t.leafs, [@c1111, @c1112, @c12, @c21]

      c @t.length, 9

      c @t.linearize, [[@root, @c1, @c11, @c111, @c1111], [@root, @c1, @c11, @c111, @c1112], [@root, @c1, @c12], [@root, @c2, @c21]]
    end

    def test_depth
      c @c1112.depth, 4
      c @root.depth, 0
    end

    def test_equality
      c @c1, @c1
      c @c1 + "1", @c11
    end

    def test_no_same_objects
      @c2 << @c1
      assert @c2.children.include?(@c1.dup)
      assert @root.children.include?(@c1)
      c @t.all.select { |n| n == @c1 }.length, 2

      new_root = "new_root".extend TreeNode
      new_root.extend(TreeNode) << @root # @root.parent = new_root

      assert !@root.root?
      assert new_root.root?

      # BUG
      # @c1 << new_root
      # assert new_root.root?

      e = assert_raises(NoMethodError) { @c21.parent = @root }
      c e.message, "protected method `parent=' called for #<Node:\"c21\">"
      c @c21.parent, @c2
    end
  end
end