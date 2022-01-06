//=============================================================================
// Helpers
//=============================================================================

float vmax(float3 v)
{
    return max(max(v.x, v.y), v.z);
}

float sdf_blend(float d1, float d2, float a)
{
    return a * d1 + (1 - a) * d2;
}


float sdf_union( float d1, float d2 ) { return min(d1,d2); }

float sdf_subtraction( float d1, float d2 ) { return max(-d1,d2); }

float sdf_intersection( float d1, float d2 ) { return max(d1,d2); }

//=============================================================================
// SDF Functions
//=============================================================================
// p = point of intersection with geometry
// c = center of sdf geometry


float sdf_sphere(float3 p, float3 c, float r)
{
    return distance(p, c) - r;
}

float sdf_box (float3 p, float3 c, float3 s)
{
    float x = max
    (   p.x - c.x - float3(s.x / 2., 0, 0),
        c.x - p.x - float3(s.x / 2., 0, 0)
    );
    float y = max
    (   p.y - c.y - float3(s.y / 2., 0, 0),
        c.y - p.y - float3(s.y / 2., 0, 0)
    );
    
    float z = max
    (   p.z - c.z - float3(s.z / 2., 0, 0),
        c.z - p.z - float3(s.z / 2., 0, 0)
    );
    float d = x;
    d = max(d,y);
    d = max(d,z);
    return d;
}

float sdf_boxcheap(float3 p, float3 c, float3 s)
{
    return vmax(abs(p-c) - s);
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = (p+halfsize, size) % halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}

//=============================================================================
// Basic SDF Objects
//=============================================================================

//table sureface
float sdf_table(float3 p)
{
    float r = 0;

    float t0 = sdf_box(p, float3(0.0,-0.25,0.0), float3(0.5,0.05,0.3));
    //table legs
    float t1 = sdf_box(p, float3(0.225,-0.35,0.125), float3(0.025,0.25,0.025));
    float t2 = sdf_box(p, float3(0.225,-0.35,-0.125), float3(0.025,0.25,0.025));
    float t3 = sdf_box(p, float3(-0.225,-0.35,0.125), float3(0.025,0.25,0.025));
    float t4 = sdf_box(p, float3(-0.225,-0.35,-0.125), float3(0.025,0.25,0.025));

    r = sdf_union(t0,t1);
    r = sdf_union(r,t2);
    r = sdf_union(r,t3);
    r = sdf_union(r,t4);

    return r;
}

float sdf_chair(float3 p)
{
    float r = 0;
    //chair seat 
    float c0 = sdf_box(p, float3(0.0,-0.3,0.15), float3(0.15,0.05,0.15));
    //legs
    float c1 = sdf_box(p, float3(0.05,-0.4,0.2), float3(0.025,0.15,0.025));
    float c2 = sdf_box(p, float3(0.05,-0.4,0.1), float3(0.025,0.15,0.025));
    float c3 = sdf_box(p, float3(-0.05,-0.4,0.2), float3(0.025,0.15,0.025));
    float c4 = sdf_box(p, float3(-0.05,-0.4,0.1), float3(0.025,0.15,0.025));

    float c5 = sdf_box(p, float3(0.0,-0.2,0.2), float3(0.15,0.2,0.05));
    

    r = sdf_union(c0,c1);
    r = sdf_union(r,c2);
    r = sdf_union(r,c3);
    r = sdf_union(r,c4);
    r = sdf_union(r,c5);

    return r;
}

float sdf_table_and_chairs(float3 p)
{
    float r = 0;
    r = sdf_table(p);
    r = sdf_union(r, sdf_chair(p + float3(0.1,0.0,-0.05)));
    r = sdf_union(r, sdf_chair(p + float3(-0.1,0.0,-0.05)));
    return r;
}

float random (float2 uv)
{
    return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
}

float sdf_complex(float3 p)
{
    float r = 0;

    float c0 = sdf_box(p, 0, float3(3,0.2,3));
    float c1 = sdf_sphere(p, 0, 1);

    r = sdf_subtraction(c0,c1);

        r = sdf_subtraction(sdf_box(p, 0, float3(0.2,3,3)), r);
        // r = sdf_union(r, sdf_sphere(p,0,0.5));
    



    return r;



    
}