// Update Vertex Shader
// OpenGL SuperBible Chapter 7
// Graham Sellers

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

uniform vec3 rayPosition;
//uniform float ciElapsedSeconds;

// Holding trigger on Vive controller or right mouse click
uniform float trigger;

// The outputs of the vertex shader are the same as the inputs
out vec3 tf_position;
out vec3 tf_prev_position;

// A uniform to hold the timestep. The application can update this.
uniform float timestep = 0.15;

// The global spring constant
uniform float spring = 50;

// Gravity
uniform vec3 gravity = vec3(0.0, -0.08, 0.0);

// Global damping constant
uniform float damping = .1;

// Spring resting length
uniform float rest_length = .035;

vec3 calcRayIntersection( vec3 pos )
{   // this is for pinching/pulling on cloth with trigger
    vec3 retPos = pos;
    if (trigger > 0.2) {
        if (rayPosition.x > pos.x - 0.07 &&
            rayPosition.x < pos.x + 0.07 &&
            rayPosition.y > pos.y - 0.07 &&
            rayPosition.y < pos.y + 0.07 &&
            rayPosition.z > pos.z - 1 &&
            rayPosition.z < pos.z + 1 &&
            connection[0] != -1 && connection[1] != -1 &&
            connection[2] != -1 && connection[3] != -1) {
            retPos = vec3(rayPosition.x, rayPosition.y, rayPosition.z);
        }
    } else {

        vec3 center = rayPosition;
        vec3 moveDirection = (pos - center);
        float l = length(moveDirection);
        float radius = 0.1;

        if (l < radius) {  // see if the pos is in the sphere
            retPos = (pos + normalize(moveDirection) * (radius - l) );
        }
    }
    return retPos;
}

void main(void)
{
    vec3 pos = position;               // pos can be our position
    pos = calcRayIntersection( pos );
    float mass = 5;               // the mass of our vertex, right now is always 1

    vec3 old_position = previousPosition; // save the previous position
    vec3 vel = pos - old_position;  // calculate velocity using current & prev position

    vec3 F = gravity * mass - vel * damping;    // F is the force on the mass
    bool fixed_node = true;                     // Becomes false when force is applied

    for( int i = 0; i < 4; i++ ) {
        if( connection[i] != -1 ) {
            // q is the position of the other vertex
            vec3 q = texelFetch(tex_position, connection[i] - 1).xyz;
            vec3 delta = q - pos;
            float point_distance = length(delta);
            F += -spring * (rest_length - point_distance) * normalize(delta);
            fixed_node = false;
        }
    }

    // If this is a fixed node, reset force to zero
    if( fixed_node ) {
        F = vec3(0.0);
    }

    // Accelleration due to force
    vec3 acc = F / mass;
    // Displacement
    vec3 displacement = vel * timestep + acc * timestep * timestep;
    displacement = clamp(displacement, vec3(-.01), vec3(.01));

    // Write the outputs
    tf_prev_position = pos;
    tf_position = pos + displacement;
}
