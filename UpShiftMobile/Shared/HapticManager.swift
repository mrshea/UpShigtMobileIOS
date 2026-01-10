//
//  HapticManager.swift
//  UpShiftMobile
//
//  Centralized haptic feedback manager for consistent tactile feedback
//  Provides subtle haptic feedback for user actions and state changes
//

import UIKit

/// Manages haptic feedback throughout the app
/// Provides consistent tactile feedback for user interactions
class HapticManager {
    /// Shared instance for app-wide haptic feedback
    static let shared = HapticManager()

    private init() {}

    /// Trigger notification-style haptic feedback
    /// - Parameter type: The type of notification feedback (success, warning, error)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Trigger impact-style haptic feedback
    /// - Parameter style: The intensity of the impact (light, medium, heavy, soft, rigid)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger selection change haptic feedback
    /// Lighter feedback for selection changes in pickers, lists, etc.
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
