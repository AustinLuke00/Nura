// AnimatedLaunchScreenView.swift
// Nura — Animated launch screen with brand logo

import SwiftUI

struct AnimatedLaunchScreenView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.nuraPrimary.opacity(0.1),
                    Color.nuraPrimaryLight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo 图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nuraPrimary, Color.nuraPrimaryMid],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.nuraPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // App 名称
                VStack(spacing: 8) {
                    Text("NURA")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.nuraPrimary)
                    
                    Text("记录宝宝成长的每一刻")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    AnimatedLaunchScreenView()
}
