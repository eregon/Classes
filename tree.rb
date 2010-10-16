=begin
Waow: this is beautiful

def printTree(tree,indent)
 if (Array === tree)
    tree.map { |child| printTree(child,indent+"|  ") }
 else
    puts(indent.gsub(/\s+$/,"--")+tree.to_s)
 end
end
printTree([1,2,[11,22,[111,222,333,444],33],3,4],"")


this give :
 |--1
 |--2
 |  |--11
 |  |--22
 |  |  |--111
 |  |  |--222
 |  |  |--333
 |  |  |--444
 |  |--33
 |--3
 |--4
=end

=begin
Tree module, represent a generic Tree structure in Ruby

There are 2 ways to work:
 Creating Node Objects as containers
or
 extending the object to a TreeNode

Only the second way is kept now.

There are 2 ways to react when trying to add an object who's already in the Tree(same object_id):
 raise an error
or
 duplicate the object

The second is maybe more handy,
 but a bit slower because it needs to dup every child added.
 It can also be a little weird because you create every time a second object
The first handle that with not allowing a change of the parent if it is already set

The second is implemented in tree/dup.rb

A third implementation is tree/fast.rb, which does not raise anything,
and then is very dangerous to use if you add children which already are in the Tree.
You then have to use .dup to every child you try to add which might be already there.

Here is a benchmark on some big Trees:
0.131 normal
0.118 dup (removing the #dup useless)
0.116 fast
=end

module TreeNode
  INDENT = 2

  # Build a Tree from an Array with the format: [root, [n1, [*n1_children], n2, [*n2_children], ...]]
  # Here is a simple example:
  # ['1', [ '11', ['111', '112'], '12' ]]
  # 1
  #   11
  #     111
  #     112
  #   12
  def self.from_ary(ary)
    if ary.size == 2 and !(Array === ary[0]) and Array === ary[1]
      ary[0].extend TreeNode
      add_children_to_parent(*ary)
    else
      raise ArgumentError, "wrong format, must be [root, [child1, [children1], child2, [children2], ...]]"
    end
  end

  private
  def self.add_children_to_parent(parent, children)
    children.each_slice(2) { |child, sub_children|
      sub_children = [] if sub_children.nil?
      parent << child
      # if sub_children ~ [c1, [cc1], c2, [cc2], ...]
      if sub_children.each_index.all? { |i| i.even? != (Array === sub_children[i]) }
        add_children_to_parent(child, sub_children)
      else
        sub_children.each { |sc| child << sc }
      end
    }
    parent
  end

  # Accessors
  protected
  def parent= p
    unless @_node_parent.nil? or @_node_parent.equal?(p) or p.nil?
      raise ArgumentError, "Not allowed to set parent if already set"
    end
    @_node_parent = p
  end

  public
  def children= children
    children.grep(TreeNode) { |n|
      n.parent >> n unless equal?(n.parent)
    }
    children.each { |c| self << c }
  end

  def parent
    @_node_parent
  end
  def children
    @_node_children
  end

  def node_init # ~ initialize
    @_node_parent ||= nil
    @_node_children ||= []
    self
  end

  def self.extended(obj) # called when extended, equivalent of ::new for a module extended
    obj.node_init
  end
  # If you want to include this module, you'll need to call node_init

  # Call real object's method instead of TreeNode's methods
  def call_object_method(method, *args, &b)
    self.class.instance_method(method).bind(self).call(*args, &b)
  end
  alias :old :call_object_method

  # Add child or children(Array)
  def << child
    case child
    when TreeNode
      raise ArgumentError, "Cannot duplicate the root" if root.equal?(child)
      child.parent = self
      @_node_children << child
      child
    when Array
      child.each { |c| self << c }
      nil
    else
      self << child.extend(TreeNode)
    end
  end

  # Remove child or children(Array)
  def >> node
    case node
    when TreeNode
      parents = all.select { |n| n.children.include? node }
      raise ArgumentError, "parent of #{node} not found" if parents.empty?
      parents.each { |par|
        node.parent = nil
        par.children.delete_if { |n| n.equal?(node) }
      }
    when Array
      node.each { |n| self >> n }
    end
  end

  def [](o)
    case o
    when Integer
      @_node_children[o]
    else
      if child = @_node_children.find { |c| c == o }
        child
      else
        raise ArgumentError, "node[o]: o must be an Integer or an Object which is equal to at least one child of the node"
      end
    end
  end

  def inspect
    "#<Node:#{super}>"
  end

  def root
    root? ? self : @_node_parent.root
  end

  def length # Returns the total number of nodes in this (sub)tree
    @_node_children.inject(1) { |sum, n| sum + n.length }
  end
  alias :size :length

  def depth # depth in the tree (depth of root = 0)
    # ascendants.length
    n, i = self, 0
    i += 1 until (n = n.parent).nil?
    i
  end

  # Boolean
  def root?
    @_node_parent.nil?
  end
  def parent?(p)
    # ascendants.include?(p)
    n = self
    (return true if n == p) until (n = n.parent).nil? # Using equal? here makes such a mess
    # false
  end
  def leaf?
    @_node_children.empty?
  end
  def first?
    self == first_sibling
  end
  def last?
    self == last_sibling
  end

  # Special nodes
  # Returns the first sibling for this node. If this is the root node, returns itself.
  def first_sibling
    root? ? self : @_node_parent.children.first
  end
  # Returns the last sibling for this node.  If this node is the root, returns itself.
  def last_sibling
    root? ? self : @_node_parent.children.last
  end

  # Enumerable
  def all
    root.descendants_with_self
  end
  def ascendants # [parent, ..., root] array of ancestors in reverse order
    # root? ? [] : [@_node_parent] + @_node_parent.ascendants
    n, a = self, []
    a << n until (n = n.parent).nil?
    a
  end
  def ascendants_with_self
    root? ? [self] : [self] + @_node_parent.ascendants_with_self
  end
  def descendants # [child1, ..., leaf]
    @_node_children.inject([]) { |desc, children| desc + [children] + children.descendants }
  end
  def descendants_with_self
    @_node_children.inject([self]) { |desc, children|
      desc +
      children.descendants_with_self
    }
  end

  def leafs
    descendants_with_self.select { |n| n.leaf? }
  end

  # Root methods
  def show_tree
    if root?
      s = "*"
    else
      s = ""
      #s << " " unless parent.last?
      s << ' ' * ((depth - 1) * INDENT)# - (parent.last? ? 0 : 1) )
      s << (last? ? "+" : "|")
      s << "-" * (INDENT-1)
      s << (leaf? ? ">" : "+")
    end
    s << " #{self}\n"

    @_node_children.each { |c| s << c.send(__method__) }
    s
  end

  def show_simple
    @_node_children.inject(
    " " * (INDENT * depth) + "#{self.to_s}\n" # to_s is added to ensure it's called even when it's a subclass of String
    ) { |s,c| s << c.send(__method__) }
  end

  def show
    show_simple
  end

  # "Linearize" a tree: return an Array representation fo the tree
  # with each leaf being the last element of each sub-Array, and the ascending nodes before
  # t = "root".extend(TreeNode)
  # t << "c1" << ["c11", "c12"]
  # t << "c2"
  # t.linearize #=>
  #  [
  #    [#<Node:"root">, #<Node:"c1">, #<Node:"c11">],
  #    [#<Node:"root">, #<Node:"c1">, #<Node:"c12">],
  #    [#<Node:"root">, #<Node:"c2">]
  #  ]
  #
  def linearize
    descendants_with_self.select(&:leaf?).map { |n| n.ascendants_with_self.reverse }
  end
end

if __FILE__ == $0
  require "minitest/autorun"
  class TestTree < MiniTest::Unit::TestCase
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
      assert_equal @root, @t.root

      assert_equal [@c11, @c111, @c1111, @c1112, @c12], @c1.descendants
      assert_equal [@c1, @c11, @c111, @c1111, @c1112, @c12], @c1.descendants_with_self

      assert_equal [@c11, @c1, @root], @c111.ascendants
      assert_equal [@c111, @c11, @c1, @root], @c111.ascendants_with_self

      assert_equal [@c1111, @c1112, @c12, @c21], @t.leafs

      assert_equal 9, @t.length

      assert_equal [
        [@root, @c1, @c11, @c111, @c1111],
        [@root, @c1, @c11, @c111, @c1112],
        [@root, @c1, @c12],
        [@root, @c2, @c21]
      ], @t.linearize
    end

    def test_depth
      assert_equal 4, @c1112.depth
      assert_equal 0, @root.depth
    end

    def test_equality
      assert_equal @c1, @c1
      assert_equal @c11, @c1 + "1"
    end

    def test_no_same_objects
      e = assert_raises(ArgumentError) { @c2 << @c1 }
      assert_equal "Not allowed to set parent if already set", e.message
      assert_equal 1, @t.all.select { |n| n == @c1 }.length

      e = assert_raises(ArgumentError) { @c1 << @c21 }
      assert_equal "Not allowed to set parent if already set", e.message
      assert_equal 1, @t.all.select { |n| n == @c21 }.length

      new_root = "new_root"
      new_root.extend(TreeNode) << @root # @root.parent = new_root.extend(TreeNode)
      assert !@root.root?
      assert new_root.root?

      e = assert_raises(ArgumentError) { @c1 << new_root }
      assert_equal "Cannot duplicate the root", e.message
      assert new_root.root?

      e = assert_raises(NoMethodError) { @c21.parent = @root }
      assert_equal "protected method `parent=' called for #<Node:\"c21\">", e.message
      assert_equal @c2, @c21.parent
    end

    def test_from_ary
      a = ['1', [ '11', ['111', '112'], '12' ]]
      t = TreeNode.from_ary(a)
      e = <<TREE
1
  11
    111
    112
  12
TREE
      assert_equal e, t.show_simple
    end

    def test_call_object_method
      str = "Strin".extend(TreeNode)

      str << "g"
      assert_equal "Strin", str
      assert_equal ["g"], str.children

      str.old(:<<, "g")
      assert_equal "String", str
      assert_equal ["g"], str.children
    end

    def test_remove
      @t >> @c2
      assert_equal [@c1], @t.children
      assert_equal nil, @c2.parent
    end
  end
end
