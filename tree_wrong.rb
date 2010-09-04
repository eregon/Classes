require_relative 'tree'
require 'wrong'
include Wrong::Assert
Wrong.config[:color] = true

@c1, @c11, @c111, @c1111, @c1112, @c12, @c2, @c21 = %w[c1 c11 c111 c1111 c1112 c12 c2 c21]
@root = @t = "root".extend(TreeNode)
@t << @c1 << @c11
@t << @c2 << @c21
@c1 << @c12
@t[0][0] << @c111 << [@c1111, @c1112]

# test_basic
assert { @t.root == @root }

assert { @c1.descendants == [@c11, @c111, @c1111, @c1112, @c12] }
assert { @c1.descendants_with_self == [@c1, @c11, @c111, @c1111, @c1112, @c12] }

assert { @c111.ascendants == [@c11, @c1, @root] }
assert { @c111.ascendants_with_self == [@c111, @c11, @c1, @root] }

assert { @t.leafs == [@c1111, @c1112, @c12, @c21] }

assert { @t.length == 9 }

assert {
  @t.linearize == [
    [@root, @c1, @c11, @c111, @c1111],
    [@root, @c1, @c11, @c111, @c1112],
    [@root, @c1, @c12],
    [@root, @c2, @c21]
  ]
}

# test_depth
assert { @c1112.depth == 4 }
assert { @root.depth == 0 }

# test_equality
assert { @c1 == @c1 }
assert { @c1 + "1" == @c11 }

# test_no_same_objects
assert { rescuing { @c2 << @c1 }.class == ArgumentError }
assert { rescuing { @c2 << @c1 }.message == "Not allowed to set parent if already setted" }
assert { @t.all.select { |n| n == @c1 }.length == 1 }

assert { rescuing { @c1 << @c21 }.class == ArgumentError }
assert { rescuing { @c1 << @c21 }.message == "Not allowed to set parent if already setted" }
assert { @t.all.select { |n| n == @c21 }.length == 1 }

new_root = "new_root"
new_root.extend(TreeNode) << @root # @root.parent = new_root.extend(TreeNode)
assert { !@root.root? }
assert { new_root.root? }

assert { rescuing { @c1 << new_root }.class == ArgumentError }
assert { rescuing { @c1 << new_root }.message == "Cannot duplicate the root" }
assert { new_root.root? }

assert { rescuing { @c21.parent = @root }.class == NoMethodError }
assert { rescuing { @c21.parent = @root }.message == "protected method `parent=' called for #<Node:\"c21\">" }
assert { @c21.parent == @c2 }

# test_from_ary
a = ['1', [ '11', ['111', '112'], '12' ]]
t = TreeNode.from_ary(a)
e = <<TREE
1
  11
    111
    112
  12
TREE
assert { t.show_simple == e }

# test_call_object_method
str = "Strin".extend(TreeNode)

str << "g"
assert { str == "Strin" }
assert { str.children == ["g"] }

str.old(:<<, "g")
assert { str == "String" }
assert { str.children == ["g"] }

# test_remove
@t >> @c2
assert { @t.children == [@c1] }
assert { @c2.parent == nil }
