--- A small library for working with trees which have n children.


---@class nNodeList
---@field nodes nTree[] The nodes in the list.
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

---@class nTree-class
local tree = {}

local t_mt = {}

function t_mt.__tostring(self)
  return "Tree Node: " .. tostring(self.value)
end

--- Create a new node.
---@param value any The value of the node.
---@return nTree tree The node.
function tree.new(value)
  ---@class nTree
  ---@field parent nTree? The parent of the node.
  ---@field children nTree[] The children of the node.
  ---@field value any The value of the node.
  ---@field n_children integer The number of children.
  ---@field _is_tree true
  local obj = {
    _is_tree = true,
    parent = nil,
    children = {},
    value = value,
    n_children = 0
  }

  --- Get the root node of the tree.
  ---@return nTree root The root node.
  function obj.get_root()
    local root = obj

    while root.parent do
      root = root.parent --[[@as nTree]]
    end

    return root
  end

  --- Insert a node.
  ---@param value any The value of the node.
  ---@return nTree node The new node.
  function obj.new_child(value)
    if type(value) == "table" and value._is_tree then
      value.parent = obj
      obj.n_children = obj.n_children + 1
      obj.children[obj.n_children] = value
      return value
    end

    local node = tree.new(value)
    node.parent = obj
    obj.n_children = obj.n_children + 1
    obj.children[obj.n_children] = node
    return node
  end

  --- Get all leaf nodes from the tree. Depth-first from left to right.
  ---@return nNodeList leaves The leaf nodes.
  function obj.get_leaves()
    local leaves = {}

    local function get_leaves(node)
      if node.n_children == 0 then
        table.insert(leaves, node)
        return
      end

      local children = node.children
      for i = 1, node.n_children do
        get_leaves(children[i])
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
  ---@return nNodeList nodes The nodes in the layer.
  function obj.get_layer(layer)
    local nodes = {}

    local function get_layer(node, current_layer)
      if current_layer == layer then
        table.insert(nodes, node)
        return
      end

      for _, child in ipairs(node.children) do
        get_layer(child, current_layer + 1)
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

      local children = node.children
      for i = 1, node.n_children do
        count_layers(children[i], current_layer + 1)
      end
    end

    count_layers(obj, 0)

    return layers
  end

  return setmetatable(obj, t_mt)
end

return tree