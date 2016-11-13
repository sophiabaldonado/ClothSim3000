local g = lovr.graphics
local width = 40
local height = 40
local vertices = {}
local previousPositions = {}
local connections = {}
local triangleIndices = {}
local points

function lovr.load()
  local gridSize = lovr.headset.isPresent() and 2 or 2
  local originY = lovr.headset.isPresent() and .8 or 0

  -- TODO 2d table?
  for j = 1, height do
    local v = j / height
    for i = 1, width do
      local u = i / width
      local x = (u - .5) * gridSize
      local y = (v - .5) * gridSize + originY
      local z = -2

      table.insert(vertices, {
        x, y, z,
        u, -v
      })

      table.insert(previousPositions, { 0, 0, 0 })
      table.insert(connections, { -1, -1, -1, -1 })

      local n = #connections
      local lastConnection = connections[n]
      if i ~= 1 then lastConnection[1] = n - 1 end
      if j ~= 1 then lastConnection[2] = n - width end
      if i ~= width then lastConnection[3] = n + 1 end
      if j ~= height then lastConnection[4] = n + width end
    end
  end

  local function index(x, y)
    return x + (y - 1) * width
  end

  for j = 1, height do
    for i = 1, width - 1 do
      table.insert(triangleIndices, index(i, j))
      table.insert(triangleIndices, index(i + 1, j))
      table.insert(triangleIndices, index(i + 1, j + 1))

      table.insert(triangleIndices, index(i, j))
      table.insert(triangleIndices, index(i + 1, j + 1))
      table.insert(triangleIndices, index(i, j + 1))
    end
  end

  shader = g.newShader([[
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
    { 'texCoord', 'float', 2 }
  }

  points = g.newBuffer(format, vertices, 'points')
  points:setDrawMode('points')
  texture = g.newTexture('water.png')
  points:setTexture(texture)
  g.setShader(shader)
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
