local OctreeLeaf = {}
OctreeLeaf.__index = OctreeLeaf
OctreeLeaf.ClassName = script.Name

function OctreeLeaf.new(coordinate, data, parent)
    local self = setmetatable({}, OctreeLeaf)
    self._coordinate = coordinate
    self._data = data
    self._parent = parent
    return self
end

function OctreeLeaf:Destroy()
    self._coordinate = nil
    self._data = nil
    self._parent = nil
end

return OctreeLeaf
