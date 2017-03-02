
#define MAX_GEOMETRY_COUNT 100
#define MAX_MARCHING_STEPS 100
#define INF 9999999999.9 // not working: 1.0 / 0.0; //In GLSL, IEEE 754 infinity can conveniently be achieved by dividing by zero:

/* This is how I'm packing the data
struct geometry_t {
    vec3 position;
    float type;
};
*/
uniform vec4 u_buffer[MAX_GEOMETRY_COUNT];
uniform int u_count; //num of objects
uniform mat4 u_unProjectTxfm;
uniform float u_farPlane;
uniform vec3 u_cameraPosition;

varying vec2 f_uv;
varying vec3 f_position;

vec4 chosenGeo;

//Convert uv to world coords
vec3 uvToWorld( vec2 uv ){
    //from uv to NDC
    vec4 vec = vec4( uv * 2.0 - 1.0, 1.0, 1.0); //+z -> +1 == greater depth, after projection
    //scale up by arbitrary z (far place)
    vec *= u_farPlane;
    //untransform
    vec4 world = u_unProjectTxfm * vec;
    return world.xyz;
    
    //Austin: u_unProjectTxfm * vec4( hdc, 1.0, 1.0 ) * u_farPlane

}

//SDF's
//
//Sphere at origin
float sphereSDF( vec3 p, float radius ){
    return length( p ) - radius;
}

float boxSDF( vec3 p, vec3 dims ){
    //ref: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
    vec3 d = abs(p) - dims;
    return min( max( d.x, max( d.y,d.z ) ), 0.0 ) + length( max( d, 0.0 ) );    
}

//IQ cone, not working, or I don't know what rh is 
// float coneSDF( vec3 p, vec2 rh ){
//     float q = length( p.xy );
//     //ref: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
//     return dot( rh, vec2( q, p.z ) );
// }

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
// ref: http://mercury.sexy/hg_sdf/
float coneSDF(vec3 p, float radius, float height) {
	vec2 q = vec2(length(p.xz), p.y);
	vec2 tip = q - vec2(0.0, height);
	vec2 mantleDir = normalize(vec2(height, radius));
	float mantle = dot(tip, mantleDir);
	float d = max(mantle, -q.y);
	float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
	
	// distance to tip
	if ((q.y > height) && (projected < 0.0)) {
		d = max(d, length(tip));
	}
	
	// distance to base ring
	if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
		d = max(d, length(q - vec2(radius, 0.0)));
	}
	return d;
}

float cylinderSDF( vec3 p, float r, float height ){
    //ref: http://mercury.sexy/hg_sdf/
    float d = length(p.xz) - r;
    d = max( d, abs(p.y) - height );
    return d;
}

float torusSDF( vec3 p, vec2 t ){
    // t is (radius, tube) ?
    //ref: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
    vec2 q = vec2( length( p.xz ) - t.x, p.y );
    return length(q) - t.y;
}

float getGeometryDist( vec3 point, vec4 buff ){

        float geoType = buff[3];
        vec3 position = vec3(buff.x, buff.y, buff.x);

        //transform point
        point = point - position; //it's just a position vector

        //calc the appropriate SDF
        if( geoType == 0.0 ){
            //Box;
            vec3 dims = vec3(1.5, 1.5, 1.5);
            return boxSDF( point, dims );
        }
        if( geoType == 1.0 ){
            //Sphere
            return sphereSDF( point, 0.75 /*radius*/);
        }
        if( geoType == 2.0 ){
            //Cone;
            //vec2 rh = normalize( vec2( 1.0, 1.0 ) );
            //return coneSDF( point, rh );
            //why isn't this working???
            return coneSDF( point, 0.9, 3.0);
        }
        if( geoType == 3.0 ){
            //vec3 tbh = vec3( 5, 1.0, 2.0 );
            return cylinderSDF( point, 0.75, 2.0);
        }
        if( geoType == 4.0 ){
            //ref: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
            vec2 t = vec2( 1.5, 0.3 );
            return torusSDF( point, t);
        }

        return INF;
}

float intersection( float d1, float d2 ){
    return max( d1, d2 );
}

//NOTE
//Need a manual loop rollout here cuz of wacky
// issues indexing u_buffer with a for loop index value
//
float getMinGeometryDistManual( vec3 point ){
    float minDist = INF;
    float dist;

    if( u_count < 1 )
        return minDist;
    dist = getGeometryDist( point, u_buffer[0] );
    if( dist < minDist ){
        minDist = dist;
        chosenGeo = u_buffer[0];
    }

    if( u_count < 2 )
        return minDist;
    dist = getGeometryDist( point, u_buffer[1] );
    if( dist < minDist ){
        minDist = dist;
        chosenGeo = u_buffer[1];
    }

    if( u_count < 3 )
        return minDist;
    dist = getGeometryDist( point, u_buffer[2] );
    if( dist < minDist ){
        minDist = dist;
        chosenGeo = u_buffer[2];
    }

    if( u_count < 4 )
        return minDist;
    dist = getGeometryDist( point, u_buffer[3] );
    if( dist < minDist ){
        minDist = dist;
        chosenGeo = u_buffer[3];
    }

    if( u_count < 5 )
        return minDist;
    dist = getGeometryDist( point, u_buffer[4] );
    if( dist < minDist ){
        minDist = dist;
        chosenGeo = u_buffer[4];
    }

    //This ones an intersection of the next two objects
    float dist1 = getGeometryDist( point, u_buffer[5] );
    float dist2 = getGeometryDist( point, u_buffer[6] );
    dist = intersection( dist1, dist2 );
    if( dist < minDist ){
        minDist = dist;
        //What a hack!
        if( dist1 > dist2 )
            chosenGeo = u_buffer[5];
        else
            chosenGeo = u_buffer[6];
    }

    //This ones an diffsernce of the next two objects
    dist1 = getGeometryDist( point, u_buffer[7] );
    dist2 = getGeometryDist( point, u_buffer[8] );
    dist = max( dist1, -dist2 );
    if( dist < minDist ){
        minDist = dist;
        if( -dist2 > dist1)
            chosenGeo = u_buffer[8];
        else
            chosenGeo = u_buffer[7];
    }
       
    return minDist;
}

vec3 getNormal( vec3 p, vec4 buff ){
    float eps = 0.05;
    return normalize( vec3( 
        getGeometryDist( vec3( p.x + eps, p.y, p.z ), buff)
        - getGeometryDist( vec3( p.x - eps, p.y, p.z ), buff),
        getGeometryDist( vec3( p.x, p.y + eps, p.z ), buff)
        - getGeometryDist( vec3( p.x, p.y - eps, p.z ), buff),
        getGeometryDist( vec3( p.x, p.y, p.z + eps ), buff)
        - getGeometryDist( vec3( p.x, p.y, p.z - eps ), buff)
    ));
}

void main() {
 

    vec3 rayEnd = uvToWorld( f_uv );
    vec3 rayStart = u_cameraPosition; //cameraPosition; //??
    //rayStart = vec3(0.0, 0.0, 10.0);
    vec3 rayDir = normalize(rayEnd - rayStart);
    float t = 0.0;
    float eps = .1;
    float maxDist = u_farPlane; //??
    float minDist = INF;
    bool onSurface = false;
    vec3 point;

    for( int step = 0; step < MAX_MARCHING_STEPS; step++ ){
        //minDist = getMinGeometryDist( rayStart + ( t * rayDir ) );

        minDist = getMinGeometryDistManual( rayStart + ( t * rayDir ) );

        // float minDist = INF; 
        // for (int c = 0; c < MAX_GEOMETRY_COUNT; c++) {
        //     if (c >= u_count) {
        //         break;
        //     }
        //     //unpack geometry buffer
        //     //vec4 pos = u_buffer[c];
        //     float type = u_buffer[c][3];
        //     float dist = INF;
        //     dist = getGeometryDist( rayStart + ( t * rayDir ), u_buffer[c][3] );
        //     minDist = min( minDist, dist );
        // }
        
        if( minDist <= eps ){
            //We're on a surface!
            onSurface = true;
            point = rayStart + ( t * rayDir );
            break;
        }
        //Not on surface, so change step size to min dist from all geometries and keep going
        t += minDist;
        //Have we gone too far?
        if ( t > maxDist )
            break;
    }

    vec4 color = vec4(0.0, 0.0, 0.0, 1.0); //background

    //We've got a hit. Git the normal and color it.
    if( onSurface == true ){
        //get the normal
        vec3 n = getNormal( point, chosenGeo );
        //color.rgb = abs(n); //vec3(1.0, 0.0, 0.0);
        
        //simple shading
        vec3 lightPos = vec3(-10.0,10.0,2.0);
        float d = clamp( dot( n, normalize( lightPos - f_position ) ), 0.0, 1.0 );
        float amb = 0.1;
        color.r = d + amb;
        color.g = d*d*d*d;
        color.b = color.g;
    }

    //debug
  //  minDist = getMinGeometryDist( rayStart );
  //  minDist = sphereSDF( rayStart, 1.0);
  //  color.r = minDist / 20.0;
  //  color.g = minDist / 10.0;
  //  color.b = minDist / 100000000000.0;

//    color.rgb = rayStart / 20.0;
    
    /*
    color.rgb = vec3(0.0,0.0,0.0);
    if(f_uv[0] < 0.3 && u_buffer[0][3] == 0.0)
        color.r = 1.0;
    else
    if( f_uv[0] < 0.6 && u_buffer[1][3] == 1.0)
        color.g = 1.0;
    else
    if( u_buffer[2][3] == 2.0 )
        color.b = 1.0;
    */
    /*
    color.rgb = vec3(0.0,0.0,0.0);
    color.r = u_buffer[0][3];
    color.g = u_buffer[1][3] / 2.0;
    color.b = u_buffer[2][3] / 2.0;
    */
    // for( int i=0; i < 3; i++){
    //     color[i] = (2.0 - u_buffer[i][3]) / float(2-i+1);
    // }

    //color.rgb = vec3(0.0,0.5,1.0);

    //Test the direction rays
    //color.rgb = (rayDir + vec3(1.0,1.0,1.0) ) / 2.0;
    //color.rgb = abs(rayDir);
    //color.b  = 0.0;

    gl_FragColor = color;
}