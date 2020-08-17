local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function isClose(a, b, eps)
    return (a-b).Magnitude <= eps
end

local DEFAULT_BOUNDS = {Vector3.new(-1E6, -1E6, -1E6), Vector3.new(1E6, 1E6, 1E6)}
return function()
    local Octree = require(ReplicatedStorage.Objects.Shared.Octree)

    local COORDS = {
        Vector3.new(0, 0, 0),
        Vector3.new(1, 1, 1),
        Vector3.new(1, 2, 1),
        Vector3.new(1, 1, 3),
        Vector3.new(1.5, 11, 1),
        Vector3.new(1, -200, 1),
    }
    describe(
        "insert",
        function()
            it(
                "should insert coords",
                function()
                    local tree = Octree.new(unpack(DEFAULT_BOUNDS))
                    for i, coord in ipairs(COORDS) do
                        tree:Insert(coord, coord)
                        expect(tree:GetSize()).to.equal(i)
                        expect(tree._dataToLeaf[coord]).to.be.ok()
                    end
                end
            )
            it(
                "should be able to find coords",
                function()
                    local tree = Octree.new(unpack(DEFAULT_BOUNDS))
                    for i, coord in ipairs(COORDS) do
                        tree:Insert(coord, coord)
                        local data, coordinate = tree:GetNearestNeighbor(coord)
                        expect(data).to.equal(coord)
                    end
                end
            )
        end
    )

    describe(
        "delete",
        function()
            it(
                "should delete coords",
                function()
                    local tree = Octree.new(unpack(DEFAULT_BOUNDS))
                    for i, coord in ipairs(COORDS) do
                        tree:Insert(coord, coord)
                        expect(tree:GetSize()).to.equal(1)
                        tree:Remove(coord)
                        expect(tree:GetSize()).to.equal(0)
                        expect(tree._dataToLeaf[coord]).to.never.be.ok()
                    end
                end
            )

            it(
                "should delete multiple coords",
                function()
                    local tree = Octree.new(unpack(DEFAULT_BOUNDS))
                    for i, coord in ipairs(COORDS) do
                        tree:Insert(coord, coord)
                    end
                    for i, coord in ipairs(COORDS) do
                        tree:Remove(coord)
                        local data, coordinate = tree:GetNearestNeighbor(coord, 1)
                        expect(data).never.to.be.ok()
                    end
                    expect(tree:GetSize()).to.equal(0)
                end
            )
        end
    )

    describe(
        "nearest-neighbor",
        function()
            it(
                "should search for nearest neighbors",
                function()
                    local eps = .5
                    local tree = Octree.new(unpack(DEFAULT_BOUNDS))
                    for i, coord in ipairs(COORDS) do
                        tree:Insert(coord, coord)
                    end
                    local test_coord = Vector3.new(.1, .1, .1)
                    local data, returned_coord = tree:GetNearestNeighbor(test_coord)
                    expect(isClose(returned_coord, test_coord, eps)).to.equal(true)

                    for _,v in pairs(COORDS) do
                        local test_coord = Vector3.new(math.random(), math.random(), math.random())/1000 + v
                        expect(isClose(test_coord, v, eps)).to.equal(true)
                        local data, returned_coord = tree:GetNearestNeighbor(test_coord)
                        expect(isClose(returned_coord, test_coord, eps)).to.equal(true)
                        expect(isClose(v, returned_coord, eps)).to.equal(true)
                    end
                end
            )
            it(
                "shouldn't return too far results",
                function()
                    local tree = Octree.new(unpack(DEFAULT_BOUNDS))
                    for i, coord in ipairs(COORDS) do
                        tree:Insert(coord, coord)
                    end
                    local test_coord = Vector3.new(1, 1, 1) * 1000
                    local data, returned_coord = tree:GetNearestNeighbor(test_coord, 10)
                    expect(data).never.to.be.ok()
                end
            )
        end
    )
end
