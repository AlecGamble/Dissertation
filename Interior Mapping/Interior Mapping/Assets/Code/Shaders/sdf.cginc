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

float sdf_add(float d1, float d2)
{
    return min(d1,d2);
}

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

