local g = lovr.graphics
local width = 25
local height = 15
local vertices = {}
local triangleIndices = {}
local points

function lovr.load()
  local gridSize = lovr.headset.isPresent() and 2 or 2
  local originY = lovr.headset.isPresent() and 2 or 0

  local positions = {}
  for j = 1, height do
    local v = j / height
    for i = 1, width do
      local u = i / width
      local x = (u - .5) * gridSize / 2
      local y = (v - .5) * gridSize + originY
      local z = 0
      local c1, c2, c3, c4 = -1, -1, -1, -1
      local n = #vertices + 1

      if j ~= height then
        if i ~= 1 then c1 = n - 1 end
        if j ~= 1 then c2 = n - width end
        if i ~= width then c3 = n + 1 end
        if j ~= height then c4 = n + width end
      end

      table.insert(vertices, {
        x, y, z,
        x, y, z,
        c1, c2, c3, c4,
        u, -v * 1.3
      })

      table.insert(positions, { x, y, z })
    end
  end

  local function index(x, y)
    return x + (y - 1) * width
  end

  for j = 1, height - 1 do
    for i = 1, width - 1 do
      table.insert(triangleIndices, index(i, j))
      table.insert(triangleIndices, index(i + 1, j))
      table.insert(triangleIndices, index(i + 1, j + 1))

      table.insert(triangleIndices, index(i, j))
      table.insert(triangleIndices, index(i + 1, j + 1))
      table.insert(triangleIndices, index(i, j + 1))
    end
  end

  updateShader = g.newShader('updateVert.glsl', nil, { 'tf_position', 'tf_prev_position' })
  renderShader = g.newShader('renderVert.glsl', 'renderFrag.glsl')

  positionBuffer = g.newBuffer({{ 'position', 'float', 3 }}, positions, 'points')
  bufferTexture = g.newTexture(positionBuffer)

  local format = {
    { 'position', 'float', 3 },
    { 'previousPosition', 'float', 3 },
    { 'connection', 'int', 4 },
    { 'texCoord', 'float', 2 }
  }

  -- Skybox
  sides = { 'right.jpg', 'left.jpg', 'top.jpg', 'bottom.jpg', 'front.jpg', 'back.jpg' }
  skybox = lovr.graphics.newSkybox(sides)


  points = g.newBuffer(format, vertices)
  texture = g.newTexture('canvas.jpg')
  points:setTexture(texture)
  leftController, rightController = lovr.headset.getController('left'), lovr.headset.getController('right')
  g.setBackgroundColor(20, 20, 20)
  t = 0
end

function lovr.update(dt)
  t = t + dt
  local trigger = math.max(leftController:getAxis('trigger'), rightController:getAxis('trigger'))
  -- renderShader:send('t', t)
  g.setShader(updateShader)
  updateShader:send('trigger', trigger)

  points:setDrawMode('points')
  points:setVertexMap()

  for _ = 1, 2 do
    updateShader:send('leftRayPosition', { leftController:getPosition() })
    updateShader:send('rightRayPosition', { rightController:getPosition() })
    updateShader:send('headRayPosition', { lovr.headset:getPosition() })
    local data = points:feedback()
    local positions = {}
    for i = 1, #data, 6 do
      local x, y, z, px, py, pz = unpack(data, i, i + 5)
      local vertexIndex = math.ceil(i / 6)
      local c1, c2, c3, c4, u, v = unpack(vertices[vertexIndex], 7, 12)
      vertices[vertexIndex] = {
        x, y, z,
        px, py, pz,
        c1, c2, c3, c4, u, v
      }
      table.insert(positions, { x, y, z })
    end
    points:setVertices(vertices)
    positionBuffer:setVertices(positions)
    bufferTexture:refresh()
  end
end

function lovr.draw()
  g.setShader()

  -- Ground
  g.setColor(45, 45, 50)
  g.plane('fill', 0, 0, 0, 5)

  -- "Controller"
  local lx, ly, lz = leftController:getPosition()
  local langle, lax, lay, laz = leftController:getOrientation()
  g.setColor(255, 255, 255)
  g.cube('line', lx, ly, lz, .2, -langle, lax, lay, laz)

  local rx, ry, rz = rightController:getPosition()
  local rangle, rax, ray, raz = rightController:getOrientation()
  g.setColor(255, 255, 255)
  g.cube('line', rx, ry, rz, .2, -rangle, rax, ray, raz)

  -- Draw triangles!
  g.setShader(renderShader)
  g.setColor(255, 255, 255)
  points:setDrawMode('triangles')
  points:setVertexMap(triangleIndices)
  points:draw()
end
