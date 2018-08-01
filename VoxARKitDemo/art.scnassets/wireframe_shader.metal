//
//  wireframe_shader.metal
//  VoxARKitDemo
//
//  Created by Shawn Campbell on 8/1/18.
//  Copyright © 2018 Shawn Campbell. All rights reserved.
//
#pragma body

float u = _surface.diffuseTexcoord.x;
float v = _surface.diffuseTexcoord.y;

float2 thickness = float2(0.005);
if (u > thickness[0] && u < (1.0 - thickness[0]) && v > thickness[1] && v < (1.0 - thickness[1])) {
    discard_fragment();
}



