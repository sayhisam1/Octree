# Octree
Lua implementation of Octree

# API
`Octree.new(corner_1: Vector3, corner_2: Vector3, <epsilon: number>)`

Creates a new Octree.

args:
- corner_1: A Vector3 denoting the left-bottom-back corner of the bounds
- corner_2: A Vector3 denoting the right-top-front corner of the bounds
- epsilon (optional): A number denoting the precision of the octree (default: 0.1). Any coordinates closer than epsilon will be treated as equal (effectively limits max tree depth)

`Octree:Insert(coordinate: Vector3, data)`

Inserts a coordinate into the octree, with some attached data (NOTE: `data` must be of a hashable type!)

`Octree:Remove(data)`

Removes the coordinate with the given data from the octree.

`Octree:GetNearestNeighbor(coordinate: Vector3, <max_dist: number>)`

Gets the nearest neighbor that is max_dist away from the coordinate. max_dist is math.huge by default.

Returns: `data`, `coordinate:Vector3`

`Octree:GetSize()`

Returns the number of data points inside the octree.

`Octree:Destroy()`

Destroys the octree (does not destroy data)