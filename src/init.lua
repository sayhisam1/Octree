--[[
	OCTREE OBJECT
@public
	Octree.new()
--]]
local OCTANTS = {
    LeftBottomBack = 1,
    LeftBottomFront = 2,
    LeftTopBack = 3,
    LeftTopFront = 4,
    RightBottomBack = 5,
    RightBottomFront = 6,
    RightTopBack = 7,
    RightTopFront = 8
}
local BOUNDS_MAP = {
    [OCTANTS.LeftBottomBack] = {1, 1, 1},
    [OCTANTS.LeftBottomFront] = {1, 1, 2},
    [OCTANTS.LeftTopBack] = {1, 2, 1},
    [OCTANTS.LeftTopFront] = {1, 2, 2},
    [OCTANTS.RightBottomBack] = {2, 1, 1},
    [OCTANTS.RightBottomFront] = {2, 1, 2},
    [OCTANTS.RightTopBack] = {2, 2, 1},
    [OCTANTS.RightTopFront] = {2, 2, 2}
}
local OCTANT_MAP = {
    [1] = {
        [1] = {
            [1] = OCTANTS.LeftBottomBack,
            [2] = OCTANTS.LeftBottomFront
        },
        [2] = {
            [1] = OCTANTS.LeftTopBack,
            [2] = OCTANTS.LeftTopFront
        }
    },
    [2] = {
        [1] = {
            [1] = OCTANTS.RightBottomBack,
            [2] = OCTANTS.RightBottomFront
        },
        [2] = {
            [1] = OCTANTS.RightTopBack,
            [2] = OCTANTS.RightTopFront
        }
    }
}

local function isClose(a, b, eps)
    return (a - b).Magnitude <= eps
end

local function getOctant(center, pos)
    local x = (pos.X <= center.X) and 1 or 2
    local y = (pos.Y <= center.Y) and 1 or 2
    local z = (pos.Z <= center.Z) and 1 or 2
    return OCTANT_MAP[x][y][z]
end

local OctreeLeaf = require(script.OctreeLeaf)
local Octree = {}

Octree.__index = Octree
Octree.ClassName = script.Name

function Octree.new(corner_1, corner_2, epsilon, parent)
    assert(typeof(corner_1) == "Vector3", "Need vector3 corner_1")
    assert(typeof(corner_2) == "Vector3", "Need vector3 corner_2")
    local self = setmetatable({}, Octree)
    self._children = {}
    self._corner1 = corner_1
    self._corner2 = corner_2
    self._center = (corner_2 - corner_1) * .5 + corner_1 -- precompute center for efficiency
    self._parent = parent
    self._epsilon = epsilon or 1E-1
    self._dataToLeaf = {}
    if parent then
        assert(parent.ClassName == Octree.ClassName, "Tried to set invalid parent!")
        self._dataToLeaf = parent._dataToLeaf
    end
    return self
end

function Octree:Destroy()
    for k, v in pairs(self._children) do
        v:Destroy()
        self._children[k] = nil
    end
    self._children = nil
    self._corner1 = nil
    self._corner2 = nil
    self._center = nil
    self._parent = nil
    self._epsilon = nil
    self._data = nil
    self._coordinate = nil
    self._dataToLeaf = nil
end

function Octree:Insert(coordinate, data)
    assert(typeof(coordinate) == "Vector3", "Coordinates must be Vector3!")
    assert(data, "Tried to insert without data!")
    if (self._center - coordinate).Magnitude <= self._epsilon then
        self._data = data
        self._coordinate = coordinate
        self._dataToLeaf[data] = self
        return self
    end

    local octant = getOctant(self._center, coordinate)
    local child = self._children[octant]
    if not child then
        self._children[octant] = OctreeLeaf.new(coordinate, data, self)
        self._dataToLeaf[data] = self._children[octant]
    elseif child.ClassName == OctreeLeaf.ClassName then
        if (child._coordinate - coordinate).Magnitude <= self._epsilon then
            error("Tried to insert duplicate point in octree!")
        end
        local c1, c2 = self:GetBounds(octant)
        local newNode = Octree.new(c1, c2, self._epsilon, self)
        self._children[octant] = newNode
        newNode:Insert(child._coordinate, child._data)
        return newNode:Insert(coordinate, data)
    else
        return child:Insert(coordinate, data)
    end
end

function Octree:GetBounds(octant)
    local bounds = BOUNDS_MAP[octant]
    local xDif = (self._center.X - self._corner1.X) * (bounds[1] - 1)
    local yDif = (self._center.Y - self._corner1.Y) * (bounds[2] - 1)
    local zDif = (self._center.Z - self._corner1.Z) * (bounds[3] - 1)
    local diffVec = Vector3.new(xDif, yDif, zDif)
    local v1 = self._corner1 + diffVec
    local v2 = self._center + diffVec
    return v1, v2
end

local function recursiveNN(node, coord, best, dist)
    if not node then
        return best, dist
    end
    if node._data then
        local currDist = (node._coordinate - coord).Magnitude
        if currDist < dist then
            best = node
            dist = currDist
        end
    end
    if node.ClassName == Octree.ClassName then
        -- check if we should even go deeper (i.e. if it's even plausible the nearest neighbor is in bounding box)
        local c1 = node._corner1
        local c2 = node._corner2
        -- lazy check (quick spherical check)
        -- #TODO: Add tighter bounds check
        local radius = (c1 - c2).Magnitude * .5
        if (node._center - coord).Magnitude < radius + dist then
            local octant = getOctant(node._center, coord)
            -- we use the octant as a heuristic for the "most likely" next child
            -- #TODO: Add better heuristics
            for i = -1, 6 do
                local curr = (octant + i) % 8 + 1
                local child = node._children[curr]
                best, dist = recursiveNN(child, coord, best, dist)
            end
        end
    end
    return best, dist
end

function Octree:GetNearestNeighbor(coordinate, max_dist)
    assert(typeof(coordinate) == "Vector3", "Coordinates must be Vector3!")
    max_dist = max_dist or math.huge
    local best, dist = recursiveNN(self, coordinate, nil, math.huge)
    if best and (coordinate - best._coordinate).Magnitude <= max_dist then
        return best._data, best._coordinate
    end
end

function Octree:Remove(data)
    assert(data, "Did not pass data to remove!")
    local leaf = self._dataToLeaf[data]
    if not leaf then
        error("Object is not in octree!")
    end
    if leaf.ClassName == Octree.ClassName then
        leaf:_RemoveChild(leaf)
    else
        leaf._parent:_RemoveChild(leaf)
    end
end

function Octree:Contains(data)
    return self._dataToLeaf[data] ~= nil
end

function Octree:_RemoveChild(child)
    if not child then
        return
    end
    if child == self then
        -- special case for when the node itself contains the data
        self._dataToLeaf[self._data] = nil
        self._data = nil
        self._coordinate = nil
    end
    local childCount = self._data and 1 or 0
    local onlyChild = (self._data and self) or nil
    for k, v in pairs(self._children) do
        if v == child then
            if child._data then
                self._dataToLeaf[child._data] = nil
            end
            self._children[k] = nil
            v:Destroy()
        else
            childCount = childCount + 1
            onlyChild = v
        end
    end
    if childCount <= 0 and self._parent and not self._data then
        self._parent:_RemoveChild(self)
    end
end

function Octree:GetSize()
    local size = (self._data and 1) or 0
    for k, v in pairs(self._children) do
        if v.ClassName == self.ClassName then
            size = size + v:GetSize()
        else
            size = size + 1
        end
    end
    return size
end

return Octree
