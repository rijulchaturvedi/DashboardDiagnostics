import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var iconScale: CGFloat = 0.7
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // App icon / logo area
                    ZStack {
                        // Glow behind icon
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.86, green: 0, blue: 0.27).opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 200, height: 200)

                        // Car icon
                        Image(systemName: "car.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.86, green: 0, blue: 0.27),
                                        Color(red: 0.55, green: 0, blue: 0.22)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(alignment: .bottomTrailing) {
                                // Warning badge
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0))
                                    .offset(x: 16, y: 8)
                            }
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                    VStack(spacing: 8) {
                        Text("Dashboard")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(textOpacity)

                        Text("Diagnostics")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.86, green: 0, blue: 0.27))
                            .opacity(textOpacity)

                        Text("Identify warning lights instantly")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                            .opacity(subtitleOpacity)
                            .padding(.top, 4)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("Designed & Developed by")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Rijul Chaturvedi")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 48)
                }
                .frame(maxHeight: .infinity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    textOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                    subtitleOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
