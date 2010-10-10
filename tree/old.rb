module Tree
  INDENT = 2

  class Node
    attr_accessor :args, :parent, :children

    def initialize(*args)
      @args = args
      @parent = nil
      @children = []
    end

    def name
      @args.first
    end

    def == o
      (o.is_a?(Node) and @args == o.args) or
      @args.include?(o)
    end

    def << child
      case child
      when Node
        @children << child
        child.parent = self
        child
      when Array
        child.each { |c| self << c }
        self
      else
        self << Node.new(child)
      end
    end
    alias :add :<<

    def >> node
      case node
      when Node
        p = all.find { |n| n.has_child? node }
        raise "can not remove the root of a tree" if p.nil?
        p.children.delete(node)
      when Array
        node.each { |n| self >> n }
      end
    end
    alias :remove :>>

    def [](o)
      case o
      when Integer
        @children[o]
      when Node
        @children.find(o)
      else
        descendants.find { |c| c.args.any? { |a| a == o } }
      end
    end
    alias :select :[]

    def to_s
      "N:#{@args.length == 1 ? @args[0].inspect : @args.inspect}"
    end
    alias :inspect :to_s

    def root
      root? ? self : @parent.root
    end

    def length # Returns the total number of nodes in this tree
      @children.inject(1) { |sum, n| sum + n.size }
    end
    alias :size :length

    def depth # depth in the tree (depth of root = 0)
      ascendants.length - 1
    end

    # Boolean
    def root?
      @parent.nil?
    end
    def parent?(p)
      ascendants.include?(p)
    end
    def has_child?(c)
      @children.include?(c)
    end
    def children?
      not @children.empty?
    end
    def leaf?
      @children.empty?
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
      root? ? self : parent.children.first
    end
    # Returns the last sibling for this node.  If this node is the root, returns itself.
    def last_sibling
      root? ? self : parent.children.last
    end

    # Enumerable
    def all
      root.descendants
    end
    def ascendants # [self, parent, ..., root] array of ancestors in reverse order, includes self
      root? ? [self] : [self] + parent.ascendants
    end
    def descendants # [self, child1, ...] includes self
      @children.inject([self]) { |desc, c| desc + c.descendants } rescue []
    end

    def leafs
      descendants.select { |n| n.leaf? }
    end

    def single_tree # return a tree containing only this node and his parents
      ascendants.reverse[1..-1].inject(Tree.new(*root.args)) { |t, n|
        t.leafs[0] << Node.new(*n.args)
      }
    end
    # Root methods
    def show_tree(lvl = 0)
      if root?
        s = "*"
      else
        s = ""
        s << "|" unless parent.last?
        # s << ' ' * (lvl - 1) * INDENT
        s << ' ' * ((lvl - 1) * INDENT - (parent.last? ? 0 : 1) )
        s << (last? ? "+" : "|")
        s << "-" * (INDENT-1)
        s << (children? ? "+" : ">")
      end

      s << " #{args.join}\n"

      @children.each { |c| s << c.send(__method__, lvl+1) }
      s
    end

    def show_simple(lvl = 0)
      @children.inject(
      " " * (INDENT * lvl) + "#{@args}\n"
      ) { |s,c| s << c.send(__method__, lvl+1) }
    end

    def show
      show_tree
    end

    def linearize
      descendants.select { |n| n.leaf? }.map { |n| n.ascendants.reverse }
    end
  end

  def new(*args)
    Node.new(*args)
  end
  module_function :new
end

if __FILE__ == $0
  include Tree

  t = Tree.new(:root)
  t <<
  Node.new(:c1) <<
  Node.new(:c11)

  t <<
  Node.new(:c2) <<
  Node.new(:c21)

  t[:c1] <<
  Node.new(:c12)

  t[0][0] <<
  Node.new(:c111) <<
  Node.new(:c1111)
  t[:c111] <<
  Node.new(:c1112)
  puts t.show

  require "minitest/autorun"
  include Tree
  class TestTree < MiniTest::Unit::TestCase
    def setup
      @c1, @c11, @c111, @c1111, @c1112, @c12, @c2, @c21 =
      [:c1, :c11, :c111, :c1111, :c1112, :c12, :c2, :c21].map { |s| Node.new(s) }
      @root = @t = Tree.new(:root)
      @t << @c1 << @c11
      @t << @c2 << @c21
      @t[@c1.name] << @c12
      @t[0][0] << @c111 << [@c1111, @c1112]
    end

    def test_basic
      assert_equal [@root, @c1, @c11, @c111, @c1111, @c1112, @c12, @c2, @c21], @t.descendants
      assert_equal [@c1112, @c111, @c11, @c1, @root], @t[@c1112.name].ascendants
      assert_equal [@c1111, @c1112, @c12, @c21], @t.leafs
      assert_equal 9, @t.length
      # assert_raise(ArgumentError) { @t << Node.new(:c21) }
      assert_equal [[@root, @c1, @c11, @c111, @c1111], [@root, @c1, @c11, @c111, @c1112], [@root, @c1, @c12], [@root, @c2, @c21]],
      @t.linearize
      # assert_equal @c1, @t[@c1]
    end
  end
end