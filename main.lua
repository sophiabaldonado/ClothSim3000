local g = lovr.graphics
local width = 50
local height = 50
local vertices = {}
local triangleIndices = {}
local points

function lovr.load()
  local gridSize = lovr.headset.isPresent() and 2 or 2
  local originY = lovr.headset.isPresent() and 6 or 0

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
        .33 + u * .667, -v
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
  renderShader = g.newShader([[
    in vec2 texCoord;
    out vec2 TexCoord;
    out vec3 Position;

    void main() {
      TexCoord = texCoord;
      Position = position;
      gl_Position = lovrProjection * lovrTransform * vec4(position, 1.0);
    }
  ]], [[
    uniform sampler2D cloth;
    uniform float t;
    in vec3 Position;
    in vec2 TexCoord;

    //  Function from Iñigo Quiles
    //  https://www.shadertoy.com/view/MsS3Wc
    vec3 hsb2rgb( in vec3 c ){
        vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                                 6.0)-3.0)-1.0,
                         0.0,
                         1.0 );
        rgb = rgb*rgb*(3.0-2.0*rgb);
        return c.z * mix(vec3(1.0), rgb, c.y);
    }

    void main() {
      color = texture(cloth, TexCoord) * vec4(hsb2rgb(vec3(abs(TexCoord.x) * 2, 1, .9)), 1);
    }
  ]])

  positionBuffer = g.newBuffer({{ 'position', 'float', 3 }}, positions, 'points')
  bufferTexture = g.newTexture(positionBuffer)

  local format = {
    { 'position', 'float', 3 },
    { 'previousPosition', 'float', 3 },
    { 'connection', 'int', 4 },
    { 'texCoord', 'float', 2 }
  }

  points = g.newBuffer(format, vertices)
  texture = g.newTexture('cloth.jpg')
  points:setTexture(texture)
  controller = lovr.headset.getController('left')
  g.setBackgroundColor(20, 20, 20)
  t = 0
end

function lovr.update(dt)
  t = t + dt
  updateShader:send('t', t)
  updateShader:send('rayPosition', { controller:getPosition() })
  updateShader:send('trigger', controller:getAxis('trigger'))

  g.setShader(updateShader)
  points:setDrawMode('points')
  points:setVertexMap()
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

function lovr.draw()
  g.setShader()

  -- Ground
  g.setColor(45, 45, 50)
  g.plane('fill', 0, 0, 0, 5)

  -- "Controller"
  local x, y, z = controller:getPosition()
  local angle, ax, ay, az = controller:getOrientation()
  g.setColor(255, 255, 255)
  g.cube('line', x, y, z, .3, -angle, ax, ay, az)

  -- Draw triangles!
  g.setShader(renderShader)
  g.setColor(255, 255, 255)
  points:setDrawMode('triangles')
  points:setVertexMap(triangleIndices)
  points:draw()
end
