local g = lovr.graphics
local pointsX = 40
local pointsY = 40
local positions = {}
local previousPositions = {}
local connections = {}
local triangleIndices = {}
local points

function lovr.load()
  local gridSize = lovr.headset.isPresent() and 2 or 2
  local originY = lovr.headset.isPresent() and .8 or 0

  -- TODO 2d table?
  for j = 1, pointsY do
    local fj = j / pointsY
    for i = 1, pointsX do
      local fi = i / pointsX

      table.insert(positions, {
        (fi - .5) * gridSize,
        (fj - .5) * gridSize + originY,
        -2
      })

      table.insert(previousPositions, { 0, 0, 0 })
      table.insert(connections, { -1, -1, -1, -1 })

      local n = #connections
      local lastConnection = connections[n]
      if i ~= 1 then lastConnection[1] = n - 1 end
      if j ~= 1 then lastConnection[2] = n - pointsX end
      if i ~= pointsX then lastConnection[3] = n + 1 end
      if j ~= pointsY then lastConnection[4] = n + pointsX end
    end
  end

  local function index(x, y)
    return x + (y - 1) * pointsX
  end

  for j = 1, pointsY do
    for i = 1, pointsX - 1 do
      table.insert(triangleIndices, index(i, j))
      table.insert(triangleIndices, index(i + 1, j))
      table.insert(triangleIndices, index(i + 1, j + 1))

      table.insert(triangleIndices, index(i, j))
      table.insert(triangleIndices, index(i + 1, j + 1))
      table.insert(triangleIndices, index(i, j + 1))
    end
  end

  points = lovr.graphics.newBuffer(positions, 'points')
  points:setDrawMode('points')
end

function lovr.update(dt)

end

function lovr.draw()

  -- Draw triangles!
  g.setColor(128, 0, 255)
  points:setDrawMode('triangles')
  points:setVertexMap(triangleIndices)
  points:draw()

  -- Clear depth buffer otherwise the points don't show up!
  g.clear(false, true)

  -- Draw points!
  g.setPointSize(4)
  g.setColor(0, 0, 0)
  points:setDrawMode('points')
  points:setVertexMap()
  points:draw()
end
