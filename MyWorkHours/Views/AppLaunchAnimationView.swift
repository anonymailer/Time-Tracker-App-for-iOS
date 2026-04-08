import SwiftUI

struct AppLaunchAnimationView: View {
    @State private var glowScale: CGFloat = 0.72
    @State private var cardOffset: CGFloat = 36
    @State private var cardOpacity = 0.0
    @State private var titleOffset: CGFloat = 18
    @State private var titleOpacity = 0.0
    @State private var iconRotation = -10.0
    @State private var creatorOpacity = 0.35

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.58, blue: 0.27),
                    Color(red: 0.98, green: 0.83, blue: 0.47),
                    Color(red: 0.96, green: 0.95, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.30))
                .frame(width: 240, height: 240)
                .blur(radius: 10)
                .scaleEffect(glowScale)

            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.white.opacity(0.28))
                        .frame(width: 132, height: 132)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(.white.opacity(0.65), lineWidth: 1.2)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 20, y: 14)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 54, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.33, green: 0.22, blue: 0.12))
                        .rotationEffect(.degrees(iconRotation))
                }
                .offset(y: cardOffset)
                .opacity(cardOpacity)

                VStack(spacing: 8) {
                    Text("MyWorkHours")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.28, green: 0.18, blue: 0.11))

                    Text("Track time with clarity")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.39, green: 0.29, blue: 0.20).opacity(0.82))

                    Text("Created by Sino Thomas")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.39, green: 0.29, blue: 0.20).opacity(0.72))
                        .opacity(creatorOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
                glowScale = 1.12
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.08)) {
                cardOffset = 0
                cardOpacity = 1
                iconRotation = 0
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.2)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.45).delay(0.35).repeatCount(3, autoreverses: true)) {
                creatorOpacity = 1
            }
        }
    }
}
