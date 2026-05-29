// LaunchScreenWithImage.swift
// Nura — Launch Screen with Real Image Asset

import SwiftUI

/// 使用真实图片资源的启动屏幕
/// 在 Assets.xcassets 中添加名为 "LaunchBackground" 的图片后使用此版本
struct LaunchScreenWithImageView: View {
    var body: some View {
        ZStack {
            // 方式1: 使用图片作为完整背景
            Image("LaunchBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // 可选：添加渐变叠加层以确保文字清晰可见
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

/// 使用自定义布局的启动屏幕（推荐用于你的设计）
struct CustomLayoutLaunchScreen: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景色 - 温暖的橙黄色
            Color(hex: "FFD97D")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo 区域
                VStack(spacing: 20) {
                    // 使用你的自定义图片
                    // 确保在 Assets.xcassets 中添加了 "LaunchLogo" 图片
                    Image("LaunchLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // Nura 文字
                    Text("Nura")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        .opacity(textOpacity)
                }
                
                Spacer()
                
                // 底部标语
                VStack(spacing: 8) {
                    Text("用心记录 · 用爱陪伴")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("宝宝成长每一刻")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Logo 缩放动画
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
            
            // Logo 淡入
            withAnimation(.easeIn(duration: 0.5)) {
                logoOpacity = 1.0
            }
            
            // 文字淡入（延迟）
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

/// 简化版启动屏幕（使用背景图片）
struct SimpleLaunchScreen: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("LaunchBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
    }
}

/// 分层启动屏幕（图片 + 元素）
struct LayeredLaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 底层：渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "FFD97D"),
                    Color(hex: "FFC247")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 中层：Logo 图片
            Image("LaunchLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 240, height: 240)
                .scaleEffect(isAnimating ? 1.0 : 0.7)
                .opacity(isAnimating ? 1.0 : 0)
            
            // 上层：文字
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Nura")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    
                    Text("用心记录 · 用爱陪伴")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .opacity(isAnimating ? 1.0 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - 使用说明

/*
 ## 如何使用这些启动屏幕：
 
 ### 步骤 1: 添加图片资源
 1. 打开 Assets.xcassets
 2. 右键 > New Image Set
 3. 命名为 "LaunchBackground" 或 "LaunchLogo"
 4. 将你的图片（Nura_1242x2688.jpg）拖入对应的槽位
 
 ### 步骤 2: 准备不同尺寸（可选但推荐）
 - @1x: 414 × 896 px
 - @2x: 828 × 1792 px
 - @3x: 1242 × 2688 px
 
 ### 步骤 3: 在 NuraApp.swift 中选择使用
 
 将 `AnimatedLaunchScreenView()` 替换为以下任一版本：
 
 ```swift
 // 完整图片背景
 LaunchScreenWithImageView()
 
 // 自定义布局（推荐）
 CustomLayoutLaunchScreen()
 
 // 简化版
 SimpleLaunchScreen()
 
 // 分层版（带动画）
 LayeredLaunchScreen()
 ```
 
 ### 步骤 4: 调整图片渲染模式（如需要）
 
 如果图片看起来太暗或太亮，可以添加：
 ```swift
 Image("LaunchBackground")
     .resizable()
     .renderingMode(.original)  // 或 .template
 ```
 
 ### 推荐方案
 
 对于你的设计（宝宝 + Nura 文字 + 橙黄色背景），推荐使用：
 - **LayeredLaunchScreen** - 如果图片是透明 PNG（只有宝宝和 Logo）
 - **SimpleLaunchScreen** - 如果图片包含完整的背景
 
 */

// MARK: - Preview

#Preview("With Image") {
    LaunchScreenWithImageView()
}

#Preview("Custom Layout") {
    CustomLayoutLaunchScreen()
}

#Preview("Simple") {
    SimpleLaunchScreen()
}

#Preview("Layered") {
    LayeredLaunchScreen()
}
