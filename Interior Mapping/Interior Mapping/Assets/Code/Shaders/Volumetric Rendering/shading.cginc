//=============================================================================
// Shading
//=============================================================================

#include "Lighting.cginc"
fixed4 specular (fixed3 normal, float3 viewDirection, float specularity, float gloss) 
{
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;    // Light direction
    fixed3 lightCol = _LightColor0.rgb;        // Light color
    fixed NdotL = max(dot(normal, lightDir),0);
    fixed4 c;
    fixed3 h = (lightDir - viewDirection) / 2.;
    fixed s = pow( dot(normal, h), specularity) * gloss;
    c.rgb = 1 * lightCol * NdotL + s;
    c.a = 1;
    return c;
}