local g = lovr.graphics
local width = 50
local height = 50
local vertices = {}
local previousPositions = {}
local connections = {}
local triangleIndices = {}
local points

function lovr.load()
  local gridSize = lovr.headset.isPresent() and 2 or 2
  local originY = lovr.headset.isPresent() and 1 or 0

  -- TODO 2d table?
  for j = 1, height do
    local v = j / height
    for i = 1, width do
      local u = i / width
      local x = (u - .5) * gridSize
      local y = (v - .5) * gridSize + originY
      local z = 0

      table.insert(connections, { -1, -1, -1, -1 })
      table.insert(crossConnections, { -1, -1, -1, -1 })

      local n = #connections
      local lastConnection = connections[n]
      local lastCrossConnection = crossConnections[n]
      if j ~= height then
        if i ~= 1 then lastConnection[1] = n - 1 end
        if j ~= 1 then lastConnection[2] = n - width end
        if j ~= 1 then lastConnection[1] = n - width - 1 end
        if j ~= 1 then lastConnection[2] = n - width + 1 end

        if i ~= width then lastCrossConnection[3] = n + 1 end
        if j ~= height then lastCrossConnection[4] = n + width end
        if j ~= height then lastCrossConnection[3] = n + width - 1 end
        if j ~= height then lastCrossConnection[4] = n + width + 1 end
      end

      local c1, c2, c3, c4 = unpack(lastConnection)

      table.insert(vertices, {
        x, y, z,
        x, y, z,
        c1, c2, c3, c4,
        .33 + u * .667, -v
      })
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

  local texFormat = {
    { 'position', 'float', 3 }
  }

  tex_position = g.newBuffer(texFormat, #vertices, 'points')

  updateShader = g.newShader('updateVert.glsl', nil, { 'tf_position', 'tf_prev_position' })
  renderShader = g.newShader([[
    in vec2 texCoord;
    out vec2 TexCoord;

    void main() {
      TexCoord = texCoord;

      gl_Position = lovrProjection * lovrTransform * vec4(position, 1.0);
    }
  ]], [[
    uniform sampler2D cloth;
    in vec2 TexCoord;

    void main() {
      color = texture(cloth, TexCoord);
    }
  ]])

  local format = {
    { 'position', 'float', 3 },
    { 'previousPosition', 'float', 3 },
    { 'connection', 'int', 4 },
    { 'texCoord', 'float', 2 }
  }

  points = g.newBuffer(format, vertices, 'points')
  points:setDrawMode('points')
  texture = g.newTexture('cloth.jpg')
  points:setTexture(texture)
  g.setShader(renderShader)

  controller = lovr.headset.getController('left')

  updateShader:send('rayPosition', { controller:getPosition() })
end

function lovr.update(dt)
    --for j = 1, 5 do
  local positions = {}
  for i = 1, #vertices do
    local p = { unpack(vertices[i], 1, 3) }
    table.insert(positions, p)
  end

  tex_position:setVertices(positions)
  local texture = g.newTexture(tex_position)
  texture:bind()

  updateShader:send('timestep', dt)
  updateShader:send('rayPosition', { controller:getPosition() })
  updateShader:send('trigger', controller:getAxis('trigger'))
  g.setShader(updateShader)
  local data = points:feedback()
  for i = 1, #data, 6 do
    local x, y, z = data[i], data[i + 1], data[i + 2]
    local px, py, pz = data[i + 3], data[i + 4], data[i + 5]

    local vertexIndex = math.floor(i / 6) + 1
    local p = vertices[vertexIndex]
    vertices[vertexIndex] = {
      x, y, z,
      px, py, pz,
      p[7], p[8], p[9], p[10],
      p[11], p[12]
    }
  end
  points:setVertices(vertices)
  --end
  g.setShader(renderShader)
end

function lovr.draw()

  -- Draw triangles!
  g.setShader(renderShader)
  g.setColor(255, 255, 255)
  points:setDrawMode('triangles')
  points:setVertexMap(triangleIndices)
  points:draw()

  -- Clear depth buffer otherwise the points don't show up!
  g.clear(false, true)

  -- Draw points!
  g.setPointSize(16)
  g.setColor(255, 255, 255)
  points:setDrawMode('points')
  points:setVertexMap()
  --points:draw()

  local x, y, z = controller:getPosition()
  g.setColor(255, 255, 255)
  g.cube('line', x, y, z, .2)
end
