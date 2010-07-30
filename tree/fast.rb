=begin
This improve the speed, while being dangerous to use
=end
require_relative '../tree'

module TreeNode
  remove_method :parent=
  protected
  def parent= p
    @_node_parent = p
  end
  public

  remove_method :<<
  def << child
    case child
    when TreeNode
      @_node_children << child
      child.parent = self
      child
    when Array
      child.each { |c| self << c }
      nil
    else
      self << child.extend(TreeNode)
    end
  end
end

if __FILE__ == $0
  require "test/unit"

  class TestTree < Test::Unit::TestCase
    def c(actual, expected)
      assert_equal(expected, actual)
    end

    def setup
      @c1, @c11, @c111, @c1111, @c1112, @c12, @c2, @c21 =
      %w[c1 c11 c111 c1111 c1112 c12 c2 c21]
      @root = @t = "root".extend(TreeNode)
      @t << @c1 << @c11
      @t << @c2 << @c21
      @c1 << @c12
      @t[0][0] << @c111 << [@c1111, @c1112]
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

      new_root = "new_root"
      new_root.extend(TreeNode) << @root # @root.parent = new_root.extend(TreeNode)
      assert !@root.root?
      assert new_root.root?

      @c1 << new_root
      assert !new_root.root?

      e = assert_raise(NoMethodError) { @c21.parent = @root }
      c e.message, "protected method `parent=' called for #<Node:\"c21\">"
      c @c21.parent, @c2
    end
  end
end