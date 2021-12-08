// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/CubemapDebug" {
    Properties {
        _Cube("Reflection Map", CUBE) = "" {}
    }
 
SubShader {
    Tags { "RenderType"="Opaque" }
 
    pass
    {      

 
        CGPROGRAM
 
        #pragma target 3.0
 
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"
 
        samplerCUBE _Cube;
        float4 _Cube_ST;
 
        struct v2f{
            float4 pos : SV_POSITION;
            float3 coord: TEXCOORD0;
        };
 
            v2f vert(appdata_base v){
                v2f o;
 
                o.pos = UnityObjectToClipPos(v.vertex);
                o.coord = v.normal;
       
                return o;
            }
 
            float4 frag(v2f i) : COLOR{
                float3 coords = normalize(i.coord);
                fixed4 result = texCUBE(_RoomCube, pos.xyz);
                return fixed4(room.rgb, 1.0);
                // float4 finalColor = 1.0;
                // float4 val = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, coords);
                // finalColor.xyz = DecodeHDR(val, unity_SpecCube0_HDR);
                // finalColor.w = 1.0;              
                // return finalColor;
            }
 
            ENDCG
        }
    }
    FallBack Off
}
 