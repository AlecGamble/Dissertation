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

    r = sdf_add(t0,t1);
    r = sdf_add(r,t2);
    r = sdf_add(r,t3);
    r = sdf_add(r,t4);

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
    

    r = min(c0,c1);
    r = min(r,c2);
    r = min(r,c3);
    r = min(r,c4);
    r = min(r,c5);

    return r;
}