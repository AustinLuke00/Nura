// AnimatedLaunchScreenView.swift
// Nura — Animated launch screen with brand logo

import SwiftUI

struct AnimatedLaunchScreenView: View {
    @State private var scale: CGFloat = 0.92
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 12
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "FFF7ED"),
                    Color(hex: "FCE7F3"),
                    Color(hex: "E0F2FE")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.82))
                        .frame(width: 132, height: 132)
                        .shadow(color: Color.nuraPrimary.opacity(0.18), radius: 24, x: 0, y: 14)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "EC4899"), Color.nuraPrimary, Color(hex: "0EA5E9")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .offset(y: offset)

                VStack(spacing: 8) {
                    Text("NURA")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "EC4899")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("从孕期到成长，用心记录每一天")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .opacity(opacity)
                .offset(y: offset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                scale = 1.0
                offset = 0
            }
            withAnimation(.easeOut(duration: 0.45)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    AnimatedLaunchScreenView()
}
