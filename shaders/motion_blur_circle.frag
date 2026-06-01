#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform vec2 uCenter;
uniform float uRadius;
uniform float uStrokeWidth;
uniform vec4 uColor;
uniform float uVelocity;

out vec4 fragColor;

// 计算到圆环边界的无向符号距离场 (SDF)
float sdRing(vec2 p, float r, float th) {
    return abs(length(p) - r) - th * 0.5;
}

void main() {
    vec2 pixelPos = FlutterFragCoord().xy;
    vec2 toCenter = pixelPos - uCenter;
    float distToCenter = length(toCenter);
    
    // 若像素过于接近圆心，直接抛弃以避免零除错误
    if (distToCenter < 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    
    // 计算当前片元到圆心的径向单位向量
    vec2 radialDir = toCenter / distToCenter;
    
    // 如果运动速度极小，直接绘制精细抗锯齿圆环与微弱外发光 (使用预乘 Alpha 混合)
    if (abs(uVelocity) < 0.1) {
        float d = sdRing(pixelPos - uCenter, uRadius, uStrokeWidth);
        float alpha = smoothstep(1.5, 0.0, d);
        
        float glowDist = abs(distToCenter - uRadius);
        float glowAlpha = smoothstep(8.0, 0.0, glowDist) * 0.25;
        
        float combinedAlpha = uColor.a * max(alpha, glowAlpha);
        fragColor = vec4(uColor.rgb * combinedAlpha, combinedAlpha);
        return;
    }
    
    // 运动拖尾：使用物理精确的解析几何扫掠体 SDF (Analytical Swept-Volume SDF)
    // 彻底摒弃离散采样循环，在 O(1) 时间内实现完美连续、无限分辨率、零分节/阶梯感的圆环运动模糊！
    
    // 计算当前距离对应的扫掠时间 t
    float t = (uRadius - distToCenter) / uVelocity;
    float clampedT = clamp(t, 0.0, 1.0);
    
    // 计算最邻近扫掠时刻的圆环半径
    float historicalRadius = uRadius - uVelocity * clampedT;
    
    // 像素到最邻近圆环的距离 SDF
    float d = abs(distToCenter - historicalRadius) - uStrokeWidth * 0.5;
    float sampleAlpha = smoothstep(1.5, 0.0, d);
    
    // 历史发光 SDF (随着扫掠范围自然平滑衰减)
    float glowDist = abs(distToCenter - historicalRadius);
    float sampleGlow = smoothstep(8.0, 0.0, glowDist) * 0.25;
    
    float sampleColor = max(sampleAlpha, sampleGlow);
    
    // 拖尾时间渐变衰减
    float decay = 1.0 - clampedT * 0.85; 
    
    float maxAlpha = sampleColor * decay;
    
    // 终极预乘 Alpha (Pre-multiplied Alpha) 混合输出，彻底解决 iOS/macOS/Windows 各显卡平台加法混合导致的“淡出失效”Bug
    float finalAlpha = uColor.a * maxAlpha;
    fragColor = vec4(uColor.rgb * finalAlpha, finalAlpha);
}
