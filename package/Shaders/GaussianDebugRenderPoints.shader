// SPDX-License-Identifier: MIT
Shader "Gaussian Splatting/Debug/Render Points"
{
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            ZWrite On
            Cull Off
            
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma require compute
#pragma use_dxc

#include "GaussianSplatting.hlsl"

StructuredBuffer<uint> _OrderBuffer;

struct v2f
{
    half4 color : COLOR0;
    float4 vertex : SV_POSITION;
};
ByteAddressBuffer _SplatSelectedBits;
float _SplatSize;
bool _DisplayIndex;
int _SplatCount;
half4 _CenterPointColor;
half4 _SelectedCenterPointColor;
uint _SplatBitsValid;

v2f vert (uint vtxID : SV_VertexID, uint instID : SV_InstanceID)
{
    v2f o;
    uint splatIndex = instID;

    SplatData splat = LoadSplatData(splatIndex);

    float3 centerWorldPos = splat.pos;
    centerWorldPos = mul(unity_ObjectToWorld, float4(centerWorldPos,1)).xyz;

    float4 centerClipPos = mul(UNITY_MATRIX_VP, float4(centerWorldPos, 1));

    o.vertex = centerClipPos;
	uint idx = vtxID;
    float2 quadPos = float2(idx&1, (idx>>1)&1) * 2.0 - 1.0;
    o.vertex.xy += (quadPos * _SplatSize / _ScreenParams.xy) * o.vertex.w;

    o.color.rgb = saturate(splat.sh.col);
    if (_DisplayIndex)
    {
        o.color.r = frac((float)splatIndex / (float)_SplatCount * 100);
        o.color.g = frac((float)splatIndex / (float)_SplatCount * 10);
        o.color.b = (float)splatIndex / (float)_SplatCount;
    }
    o.color.a = f16tof32(1.0);
    	// is this splat selected?
	if (_SplatBitsValid)
	{
        instID = _OrderBuffer[instID];
		uint wordIdx = instID / 32;
		uint bitIdx = instID & 31;
		uint selVal = _SplatSelectedBits.Load(wordIdx * 4);
		if (selVal & (1 << bitIdx))
		{
		    o.color.a = f16tof32(-1.0);			
		}
	}

    return o;
}

half4 frag (v2f i) : SV_Target
{
    if (i.color.a >= 0)
	{
        return half4(_CenterPointColor);
	}
	else
	{
        return half4(_SelectedCenterPointColor);
	}    
}
ENDCG
        }
    }
}
