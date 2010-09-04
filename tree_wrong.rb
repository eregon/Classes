require_relative 'tree'
require 'wrong'
require 'wrong/adapters/rspec'
require 'rspec/autorun'
include Wrong::Assert
Wrong.config[:color] = true

describe TreeNode do
  %w[c1 c11 c111 c1111 c1112 c12 c2 c21].each { |node|
    let(node) { node.dup }
  }

  let(:root) {
    "root".extend TreeNode
  }

  let(:t) {
    t = root
    t << c1 << c11
    t << c2 << c21
    c1 << c12
    t[0][0] << c111 << [c1111, c1112]
    t
  }

  before(:each) { t }

  it "acts like a tree" do
    # "a".should == "b"
    # assert { "a" == "b" }
    assert { t.root == root }

    assert { c1.descendants == [c11, c111, c1111, c1112, c12] }
    assert { c1.descendants_with_self == [c1, c11, c111, c1111, c1112, c12] }

    assert { c111.ascendants == [c11, c1, root] }
    assert { c111.ascendants_with_self == [c111, c11, c1, root] }

    assert { t.leafs == [c1111, c1112, c12, c21] }

    assert { t.length == 9 }

    assert {
      t.linearize == [
        [root, c1, c11, c111, c1111],
        [root, c1, c11, c111, c1112],
        [root, c1, c12],
        [root, c2, c21]
      ]
    }
  end

  it "can know its depth" do
    assert { c1112.depth == 4 }
    assert { root.depth == 0 }
  end

  it "respect true object equality" do
    assert { c1 == t.children.first }
    assert { c1.equal? t.children.first }
    assert { c1.object_id == t.children.first.object_id }
    assert { c1 + "1" == c11 }
  end

  it "deny to change parent if already set" do
    assert { rescuing { c2 << c1 }.class == ArgumentError }
    assert { rescuing { c2 << c1 }.message == "Not allowed to set parent if already set" }
    assert { t.all.select { |n| n == c1 }.length == 1 }

    lambda { c1 << c21 }.should raise_error ArgumentError, "Not allowed to set parent if already set"
    assert { t.all.select { |n| n == c21 }.length == 1 }
  end

  it "can even change root" do
    new_root = "new_root"
    new_root.extend(TreeNode) << root # root.parent = new_root.extend(TreeNode)
    deny { root.root? }
    assert { new_root.root? }

    assert { rescuing { c1 << new_root }.class == ArgumentError }
    assert { rescuing { c1 << new_root }.message == "Cannot duplicate the root" }
    assert { new_root.root? }

    assert { rescuing { c21.parent = root }.class == NoMethodError }
    assert { rescuing { c21.parent = root }.message == "protected method `parent=' called for #<Node:\"c21\">" }
    assert { c21.parent == c2 }
  end

  it "can ouput properly" do
    s = <<TREE
root
  c1
    c11
      c111
        c1111
        c1112
    c12
  c2
    c21
TREE
    assert { t.show_simple == s }
  end

  it "can import from an Array and ouput properly" do
    a = ['1', [ '11', ['111', '112'], '12' ]]
    t = TreeNode.from_ary(a)
    s = <<TREE
1
  11
    111
    112
  12
TREE
    assert { t.show_simple == s }
  end

  it "can call overriden object methods with #old" do
    str = "Strin".extend TreeNode

    str << "g"
    assert { str == "Strin" }
    assert { str.children == ["g"] }

    str.old :<<, "g"
    assert { str == "String" }
    assert { str.children == ["g"] }
  end

  it "can remove nodes" do
    t >> c2
    assert { t.children == [c1] }
    deny { c2.parent }
  end
end
