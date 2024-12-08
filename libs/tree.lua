--- A small library for working with trees.


---@class NodeList
---@field nodes Tree[] The nodes in the list.
local node_list = {}

local nl_mt = {__index = node_list}

--- Convert the list of nodes into a list of values
---@return any[] values The values of the nodes.
function node_list:as_values()
  local values = {}

  for _, node in ipairs(self.nodes) do
    table.insert(values, node.value)
  end

  return values
end

---@class Tree-class
local tree = {}

local t_mt = {}

function t_mt.__tostring(self)
  return "Tree Node: " .. tostring(self.value)
end

--- Create a new node.
---@param value any The value of the node.
---@return Tree tree The node.
function tree.new(value)
  ---@class Tree
  ---@field parent Tree? The parent of the node.
  ---@field left Tree? The left child of the node.
  ---@field right Tree? The right child of the node.
  local obj = {
    _is_tree = true,
    parent = nil,
    left = nil,
    right = nil,
    value = value
  }

  --- Get the root node of the tree.
  ---@return Tree root The root node.
  function obj.get_root()
    local root = obj

    while root.parent do
      root = root.parent --[[@as Tree]]
    end

    return root
  end

  --- Insert a new node for the left child. If the value is a node, it will be
  --- used directly as the left child. Otherwise, a new node will be created
  --- with the value.
  ---@param value any The value of the node.
  ---@return Tree node The new node.
  function obj.new_left(value)
    if type(value) == "table" and value._is_tree then
      value.parent = obj
      obj.left = value
      return value
    end

    local node = tree.new(value)
    node.parent = obj
    obj.left = node
    return node
  end

  --- Insert a new node for the right child. If the value is a node, it will be
  --- used directly as the right child. Otherwise, a new node will be created
  --- with the value.
  ---@param value any The value of the node.
  ---@return Tree node The new node.
  function obj.new_right(value)
    if type(value) == "table" and value._is_tree then
      value.parent = obj
      obj.right = value
      return value
    end

    local node = tree.new(value)
    node.parent = obj
    obj.right = node
    return node
  end

  --- Get all leaf nodes from the tree. Depth-first from left to right.
  ---@return NodeList leaves The leaf nodes.
  function obj.get_leaves()
    local leaves = {}

    local function get_leaves(node)
      if not node.left and not node.right then
        table.insert(leaves, node)
        return
      end

      if node.left then
        get_leaves(node.left)
      end

      if node.right then
        get_leaves(node.right)
      end
    end

    get_leaves(obj)

    local list = {
      nodes = leaves
    }

    return setmetatable(list, nl_mt)
  end

  --- Get all nodes in a specific layer of the tree.
  --- Layer 0 is the root node.
  ---@param layer integer The layer to get.
  ---@return NodeList nodes The nodes in the layer.
  function obj.get_layer(layer)
    local nodes = {}

    local function get_layer(node, current_layer)
      if current_layer == layer then
        table.insert(nodes, node)
        return
      end

      if node.left then
        get_layer(node.left, current_layer + 1)
      end

      if node.right then
        get_layer(node.right, current_layer + 1)
      end
    end

    get_layer(obj, 0)

    local list = {
      nodes = nodes
    }

    return setmetatable(list, nl_mt)
  end

  --- Count the number of layers in the tree.
  ---@return integer layers The number of layers.
  function obj.count_layers()
    local layers = 0

    local function count_layers(node, current_layer)
      if current_layer > layers then
        layers = current_layer
      end

      if node.left then
        count_layers(node.left, current_layer + 1)
      end

      if node.right then
        count_layers(node.right, current_layer + 1)
      end
    end

    count_layers(obj, 0)

    return layers
  end

  return setmetatable(obj, t_mt)
end

return tree