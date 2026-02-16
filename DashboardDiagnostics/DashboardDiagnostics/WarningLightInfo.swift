import SwiftUI

enum UrgencyLevel: String, CaseIterable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Info"

    var color: Color {
        switch self {
        case .critical: return .red
        case .warning: return Color.orange
        case .info: return Color.blue
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct WarningLightInfo: Identifiable {
    let id: String
    let displayName: String
    let urgency: UrgencyLevel
    let shortDescription: String
    let whatItMeans: String
    let whatToDo: String
    let symbolColor: Color

    static let database: [String: WarningLightInfo] = {
        var db = [String: WarningLightInfo]()
        for info in allLights { db[info.id] = info }
        return db
    }()

    static func lookup(_ classLabel: String) -> WarningLightInfo {
        database[classLabel] ?? WarningLightInfo(
            id: classLabel,
            displayName: classLabel.replacingOccurrences(of: "_", with: " ").capitalized,
            urgency: .warning,
            shortDescription: "Unrecognized dashboard symbol.",
            whatItMeans: "This symbol was not found in the built-in database.",
            whatToDo: "Consult your vehicle's owner's manual for details.",
            symbolColor: .orange
        )
    }

    static let allLights: [WarningLightInfo] = [
        // ─── CRITICAL ───
        WarningLightInfo(id: "battery", displayName: "Battery / Charging", urgency: .critical,
            shortDescription: "Charging system malfunction.",
            whatItMeans: "The alternator is not charging the battery. The vehicle is running on stored battery power, which will deplete within 30-60 minutes.",
            whatToDo: "Turn off non-essential electronics. Drive to the nearest safe location. Do not turn off the engine, as it may not restart.",
            symbolColor: .red),
        WarningLightInfo(id: "oil_pressure", displayName: "Oil Pressure", urgency: .critical,
            shortDescription: "Low oil pressure detected.",
            whatItMeans: "Engine oil pressure has dropped below safe levels. Running without adequate oil pressure causes severe engine damage within minutes.",
            whatToDo: "Pull over and stop the engine immediately. Check oil level with the dipstick. If oil level is fine, do not drive. Call for a tow.",
            symbolColor: .red),
        WarningLightInfo(id: "temperature", displayName: "Engine Temperature", urgency: .critical,
            shortDescription: "Engine is overheating.",
            whatItMeans: "Coolant temperature has exceeded safe limits. Causes include low coolant, failed thermostat, or radiator fan failure.",
            whatToDo: "Pull over safely. Turn off A/C and turn heater to max. Let engine cool 15+ minutes. Do not open radiator cap while hot.",
            symbolColor: .red),
        WarningLightInfo(id: "brake", displayName: "Brake System", urgency: .critical,
            shortDescription: "Brake system warning.",
            whatItMeans: "Could indicate low brake fluid, worn pads, or hydraulic fault. May also light up if parking brake is partially engaged.",
            whatToDo: "Check parking brake first. If released, check brake fluid. If pedal feels soft, avoid driving and call for service.",
            symbolColor: .red),
        WarningLightInfo(id: "airbag", displayName: "Airbag / SRS", urgency: .critical,
            shortDescription: "Supplemental Restraint System fault.",
            whatItMeans: "The airbag system has a malfunction. Airbags may not deploy in a collision, or could deploy unexpectedly.",
            whatToDo: "Get checked as soon as possible. Vehicle is safe to drive, but crash protection is compromised.",
            symbolColor: .red),
        WarningLightInfo(id: "transmission", displayName: "Transmission", urgency: .critical,
            shortDescription: "Transmission malfunction detected.",
            whatItMeans: "The transmission control module detected a fault. The vehicle may enter 'limp mode' (limited to one gear).",
            whatToDo: "Reduce speed. If in limp mode, drive directly to a shop. If you smell burning, pull over and call a tow.",
            symbolColor: .orange),

        // ─── WARNING ───
        WarningLightInfo(id: "check_engine", displayName: "Check Engine", urgency: .warning,
            shortDescription: "Engine or emissions system fault.",
            whatItMeans: "The ECU detected a fault. Could range from a loose gas cap to a serious misfire.",
            whatToDo: "Steady light: schedule a diagnostic scan soon. Flashing: reduce speed immediately, avoid hard acceleration.",
            symbolColor: .orange),
        WarningLightInfo(id: "abs", displayName: "ABS", urgency: .warning,
            shortDescription: "Anti-lock braking system fault.",
            whatItMeans: "ABS is disabled. Normal brakes work, but anti-lock function is unavailable.",
            whatToDo: "Drive cautiously in wet/icy conditions. Avoid hard braking. If both ABS and brake lights are on, stop immediately.",
            symbolColor: .orange),
        WarningLightInfo(id: "seatbelt", displayName: "Seatbelt", urgency: .warning,
            shortDescription: "Seatbelt not fastened.",
            whatItMeans: "Driver or passenger seatbelt not buckled, or cargo on seat triggering sensor.",
            whatToDo: "Fasten all seatbelts. Move cargo to trunk if triggering sensor.",
            symbolColor: .red),
        WarningLightInfo(id: "tire_pressure", displayName: "Tire Pressure (TPMS)", urgency: .warning,
            shortDescription: "Tire pressure low or uneven.",
            whatItMeans: "One or more tires significantly below recommended pressure. Increases stopping distance and reduces fuel economy.",
            whatToDo: "Check all tires with a gauge. Inflate to pressure on door jamb sticker. If light persists, check for slow leak.",
            symbolColor: .orange),
        WarningLightInfo(id: "fuel", displayName: "Low Fuel", urgency: .warning,
            shortDescription: "Fuel level is low.",
            whatItMeans: "Approximately 1-2 gallons remaining (~30-50 miles).",
            whatToDo: "Refuel at the next available station.",
            symbolColor: .orange),
        WarningLightInfo(id: "door_ajar", displayName: "Door Ajar", urgency: .warning,
            shortDescription: "A door, hood, or trunk is not fully closed.",
            whatItMeans: "One or more doors or the hood/trunk is not properly latched.",
            whatToDo: "Stop safely, check all doors, hood, and trunk. Close firmly until latch clicks.",
            symbolColor: .red),
        WarningLightInfo(id: "traction_control", displayName: "Traction Control", urgency: .warning,
            shortDescription: "Traction control active or disabled.",
            whatItMeans: "Flashing: actively preventing wheel spin. Steady: system off or faulty.",
            whatToDo: "Flashing: reduce speed. Steady and you didn't disable it: schedule diagnostic.",
            symbolColor: .orange),
        WarningLightInfo(id: "power_steering", displayName: "Power Steering", urgency: .warning,
            shortDescription: "Power steering assist reduced or lost.",
            whatItMeans: "Steering will be significantly harder to turn, especially at low speeds.",
            whatToDo: "Drive slowly, avoid tight maneuvers. Get repaired promptly.",
            symbolColor: .orange),
        WarningLightInfo(id: "parking_brake", displayName: "Parking Brake", urgency: .warning,
            shortDescription: "Parking brake is engaged.",
            whatItMeans: "Driving with it on causes brake overheating and damage.",
            whatToDo: "Fully release parking brake. If light stays on, check brake fluid.",
            symbolColor: .red),
        WarningLightInfo(id: "esp", displayName: "Electronic Stability", urgency: .warning,
            shortDescription: "Stability control active or disabled.",
            whatItMeans: "Flashing: correcting a skid. Steady with 'OFF': manually disabled or fault.",
            whatToDo: "Flashing: slow down. If you didn't disable it, schedule a check.",
            symbolColor: .orange),
        WarningLightInfo(id: "master_warning", displayName: "Master Warning", urgency: .warning,
            shortDescription: "General warning requiring attention.",
            whatItMeans: "A catch-all warning. Usually accompanied by a message on the dashboard display indicating the specific issue.",
            whatToDo: "Check your dashboard display for an accompanying message. Address the specific issue indicated.",
            symbolColor: .orange),
        WarningLightInfo(id: "key_warning", displayName: "Key / Immobilizer", urgency: .warning,
            shortDescription: "Key fob not detected or low battery.",
            whatItMeans: "The vehicle cannot detect the key fob, or the fob battery is low.",
            whatToDo: "Bring key fob closer to the start button. Replace fob battery (usually CR2032).",
            symbolColor: .red),
        WarningLightInfo(id: "hood_trunk_open", displayName: "Hood / Trunk Open", urgency: .warning,
            shortDescription: "Hood or trunk is not properly closed.",
            whatItMeans: "The hood or trunk latch is not fully engaged.",
            whatToDo: "Stop safely. Close hood/trunk firmly. If light persists, latch sensor may be faulty.",
            symbolColor: .red),
        WarningLightInfo(id: "service_engine", displayName: "Service / Maintenance", urgency: .warning,
            shortDescription: "Scheduled maintenance is due.",
            whatItMeans: "The vehicle's maintenance timer has triggered. Usually for oil change, filter, or inspection.",
            whatToDo: "Schedule routine maintenance. This can often be reset after service.",
            symbolColor: .orange),
        WarningLightInfo(id: "dpf_warning", displayName: "DPF Warning", urgency: .warning,
            shortDescription: "Diesel particulate filter needs regeneration.",
            whatItMeans: "The DPF is clogged with soot. Common in diesel vehicles driven mainly in city traffic.",
            whatToDo: "Drive at highway speed (60+ mph) for 15-20 minutes to allow passive regeneration. If light persists, see a dealer.",
            symbolColor: .orange),
        WarningLightInfo(id: "glow_plug", displayName: "Glow Plug", urgency: .warning,
            shortDescription: "Diesel glow plug warming or faulty.",
            whatItMeans: "On diesel vehicles, glow plugs preheat the combustion chamber. If the light stays on after starting, a plug may be faulty.",
            whatToDo: "Wait for light to turn off before starting (cold weather). If it stays on while driving, schedule a check.",
            symbolColor: .orange),
        WarningLightInfo(id: "lane_departure", displayName: "Lane Departure", urgency: .warning,
            shortDescription: "Lane departure warning active.",
            whatItMeans: "The camera detected the vehicle drifting out of its lane without a turn signal.",
            whatToDo: "Steer back into your lane. If fatigued, take a break.",
            symbolColor: .orange),
        WarningLightInfo(id: "blind_spot", displayName: "Blind Spot Monitor", urgency: .warning,
            shortDescription: "Vehicle detected in blind spot.",
            whatItMeans: "A vehicle is in your blind spot area. Do not change lanes.",
            whatToDo: "Wait for the indicator to clear before changing lanes. Check mirrors.",
            symbolColor: .orange),
        WarningLightInfo(id: "frost_warning", displayName: "Frost Warning", urgency: .warning,
            shortDescription: "Outside temperature near freezing.",
            whatItMeans: "Road surface may be icy. Typically activates below 37°F (3°C).",
            whatToDo: "Drive cautiously. Increase following distance. Avoid sudden braking or steering.",
            symbolColor: .orange),
        WarningLightInfo(id: "washer_fluid", displayName: "Washer Fluid Low", urgency: .info,
            shortDescription: "Windshield washer fluid is low.",
            whatItMeans: "Washer fluid reservoir needs refilling.",
            whatToDo: "Refill with appropriate fluid for your climate.",
            symbolColor: .orange),

        // ─── INFO ───
        WarningLightInfo(id: "high_beam", displayName: "High Beam", urgency: .info,
            shortDescription: "High beam headlights are on.",
            whatItMeans: "Normal indicator. High beams active.",
            whatToDo: "Switch to low beams when approaching other vehicles or in fog.",
            symbolColor: .blue),
        WarningLightInfo(id: "low_beam", displayName: "Low Beam", urgency: .info,
            shortDescription: "Low beam headlights are on.",
            whatItMeans: "Normal status indicator.",
            whatToDo: "No action needed.",
            symbolColor: .green),
        WarningLightInfo(id: "turn_signal", displayName: "Turn Signal", urgency: .info,
            shortDescription: "Turn signal active.",
            whatItMeans: "Normal operation. Rapid flashing usually means a bulb is burned out.",
            whatToDo: "No action unless flashing rapidly, then replace bulb.",
            symbolColor: .green),
        WarningLightInfo(id: "fog_light", displayName: "Fog Light", urgency: .info,
            shortDescription: "Fog lights are on.",
            whatItMeans: "Front or rear fog lights active.",
            whatToDo: "Turn off when visibility improves. Using fog lights in clear conditions may be illegal.",
            symbolColor: .green),
        WarningLightInfo(id: "cruise_control", displayName: "Cruise Control", urgency: .info,
            shortDescription: "Cruise control is active.",
            whatItMeans: "The vehicle is maintaining a set speed automatically.",
            whatToDo: "Tap brake or press cancel to deactivate.",
            symbolColor: .green),
        WarningLightInfo(id: "adaptive_cruise", displayName: "Adaptive Cruise", urgency: .info,
            shortDescription: "Adaptive cruise control active.",
            whatItMeans: "Vehicle is maintaining speed and distance from the car ahead using radar/camera.",
            whatToDo: "Stay attentive. The system may not detect all obstacles.",
            symbolColor: .green),
        WarningLightInfo(id: "auto_headlights", displayName: "Auto Headlights", urgency: .info,
            shortDescription: "Automatic headlights active.",
            whatItMeans: "Headlights turn on/off automatically based on ambient light.",
            whatToDo: "No action needed.",
            symbolColor: .green),
        WarningLightInfo(id: "auto_start_stop", displayName: "Auto Start-Stop", urgency: .info,
            shortDescription: "Auto start-stop system active.",
            whatItMeans: "Engine will automatically shut off at stops and restart when you lift the brake.",
            whatToDo: "Normal operation. Press the disable button if you prefer to keep the engine running.",
            symbolColor: .green),
        WarningLightInfo(id: "hill_assist", displayName: "Hill Start Assist", urgency: .info,
            shortDescription: "Hill start assist active.",
            whatItMeans: "Brakes are temporarily held to prevent rollback when starting on a hill.",
            whatToDo: "Normal operation. Apply gas to release.",
            symbolColor: .green),
        WarningLightInfo(id: "rear_fog", displayName: "Rear Fog Light", urgency: .info,
            shortDescription: "Rear fog light is on.",
            whatItMeans: "The rear high-intensity fog light is active.",
            whatToDo: "Turn off when visibility improves to avoid dazzling drivers behind you.",
            symbolColor: .orange),
    ]
}
