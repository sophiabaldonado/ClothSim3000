// This input vector contains the vertex position in xyz, and the
// mass of the vertex in w
//in vec4 position;        // POSITION_INDEX
// This is the previous of the vertex
in vec3 previousPosition;	// PREV_POSITION_INDEX
// This is our connection vector
in ivec4 connection;          // CONNECTION_INDEX

// This is a TBO that will be bound to the same buffer as the
// position_mass input attribute
uniform samplerBuffer tex_position;

uniform vec3 leftRayPosition;
uniform vec3 rightRayPosition;
uniform vec3 headRayPosition;

// Holding trigger on Vive controller or right mouse click
uniform float trigger;

// The outputs of the vertex shader are the same as the inputs
out vec3 tf_position;
out vec3 tf_prev_position;

// A uniform to hold the timestep. The application can update this.
uniform float timestep = .05;

// The global spring constant
uniform float spring = 40;

// Gravity
uniform vec3 gravity = vec3(0.0, -0.03, 0.0);

// Global damping constant
uniform float damping = .975;

// Spring resting length
uniform float rest_length = .035;

vec3 calcRayIntersection(vec3 pos) {
    vec3 retPos = pos;
    vec3 lCenter = leftRayPosition;
    vec3 rCenter = rightRayPosition;
    vec3 hCenter = headRayPosition;
    vec3 lMoveDirection = (pos - lCenter);
    vec3 rMoveDirection = (pos - rCenter);
    vec3 hMoveDirection = (pos - hCenter);
    float l = length(lMoveDirection);
    float r = length(rMoveDirection);
    float h = length(hMoveDirection);
    float radius = 0.3;

    if (l < radius) {  // see if the pos is in the sphere
        retPos = (pos + normalize(lMoveDirection) * (radius - l));
    } else if (r < radius) {  // see if the pos is in the sphere
        retPos = (pos + normalize(rMoveDirection) * (radius - r));
    } else if (h < radius) {
        retPos = (pos + normalize(hMoveDirection) * (radius - h));
    }

    return retPos;
}

void main() {

    // Don't do anything if I'm a boring fixed node
    if (connection == vec4(-1)) {
        tf_prev_position = position;
        tf_position = position;
        return;
    }

    vec3 pos = position;               // pos can be our position
    pos = calcRayIntersection( pos );
    float mass = 20;               // the mass of our vertex, right now is always 1

    vec3 old_position = previousPosition; // save the previous position
    vec3 vel = (pos - old_position) * damping;  // calculate velocity using current & prev position
    vel *= 1 - trigger;
    vec3 F = gravity * mass - vel * damping;    // F is the force on the mass

    for (int i = 0; i < 4; i++) {
        if( connection[i] != -1 ) {
            // q is the position of the other vertex
            vec3 q = texelFetch(tex_position, connection[i] - 1).xyz;
            vec3 delta = q - pos;
            float point_distance = length(delta);
            F += -spring * (rest_length - point_distance) * normalize(delta);
        }
    }

    vec3 acc = F / mass;
    vec3 displacement = vel + acc * timestep * timestep;

    // Write the outputs
    tf_prev_position = pos;
    tf_position = pos + displacement;
}
