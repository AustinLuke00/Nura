// LaunchScreenView.swift
// Nura — Launch Screen

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // 背景渐变色 - 温暖的橙黄色
            LinearGradient(
                colors: [
                    Color(hex: "FFD97D"),
                    Color(hex: "FFC247")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Nura Logo 和品牌
                VStack(spacing: 16) {
                    // 宝宝图标 - 使用 SF Symbols 作为占位符
                    // 实际使用时应该用你的图片资源
                    ZStack {
                        // 白色圆形背景
                        Circle()
                            .fill(.white)
                            .frame(width: 180, height: 180)
                            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                        
                        // 如果你有图片资源，取消下面的注释并使用
                        // Image("LaunchLogo")
                        //     .resizable()
                        //     .scaledToFit()
                        //     .frame(width: 180, height: 180)
                        
                        // 临时使用 SF Symbol
                        VStack(spacing: 8) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 80, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.nuraPrimary, .nuraPrimaryMid],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("N")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "FFC247"))
                        }
                    }
                    
                    // Nura 品牌名称
                    Text("Nura")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
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
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Preview

#Preview("Launch Screen") {
    LaunchScreenView()
}

#Preview("Animated Launch Screen") {
    AnimatedLaunchScreenView()
}
