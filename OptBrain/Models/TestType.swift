import Foundation

enum TestType: String, Codable, CaseIterable, Identifiable {
    case reactionTime
    case stroop
    case numberOrder
    case memoryMatch

    var id: String { rawValue }

    var displayKey: String {
        switch self {
        case .reactionTime: return "test.reactionTime.title"
        case .stroop:       return "test.stroop.title"
        case .numberOrder:  return "test.numberOrder.title"
        case .memoryMatch:  return "test.memoryMatch.title"
        }
    }

    var subtitleKey: String {
        switch self {
        case .reactionTime: return "test.reactionTime.subtitle"
        case .stroop:       return "test.stroop.subtitle"
        case .numberOrder:  return "test.numberOrder.subtitle"
        case .memoryMatch:  return "test.memoryMatch.subtitle"
        }
    }

    var symbol: String {
        switch self {
        case .reactionTime: return "bolt.fill"
        case .stroop:       return "paintpalette.fill"
        case .numberOrder:  return "square.grid.3x3.fill"
        case .memoryMatch:  return "rectangle.on.rectangle.angled"
        }
    }
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning, afternoon, evening, night

    static func bucket(for date: Date, calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default:      return .night
        }
    }

    var displayKey: String {
        switch self {
        case .morning:   return "tod.morning"
        case .afternoon: return "tod.afternoon"
        case .evening:   return "tod.evening"
        case .night:     return "tod.night"
        }
    }
}
