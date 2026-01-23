//
//  ContentView.swift
//  heart thing Watch App
//
//  Created by Jay on 23/01/2026.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            if !viewModel.authorizationStatusDetermined {
                ProgressView("Requesting HealthKit Access...")
            } else if viewModel.authorizationDenied {
                Text("HealthKit access was denied. Please enable it in the Health app on your iPhone.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .padding()
            } else {
                heartRateView
            }
        }
        .onAppear {
            viewModel.start()
        }
    }

    private var heartRateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.red)
                .frame(width: 100)
                .scaleEffect(viewModel.heartRate > 0 ? 1.2 : 1.0)
                .animation(animation, value: viewModel.heartRate)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(viewModel.heartRate > 0 ? String(format: "%.0f", viewModel.heartRate) : "--")
                    .font(.system(.largeTitle, design: .rounded).bold())
                Text(viewModel.heartRate > 0 ? "BPM" : "")
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var animation: Animation? {
        guard viewModel.heartRate > 0 else {
            // Return to normal size with a gentle spring when heart rate is 0.
            return .spring()
        }
        // Calculate the duration of one beat.
        let beatDuration = 60.0 / viewModel.heartRate
        // The animation should go from small to big in half the beat duration,
        // and then reverse.
        return .easeInOut(duration: beatDuration / 2).repeatForever(autoreverses: true)
    }
}

#Preview {
    ContentView()
}
