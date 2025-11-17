import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "todayCount",
                displayName: "Today's Entries",
                supportedFamilies: CLKComplicationFamily.allCases
            ),
            CLKComplicationDescriptor(
                identifier: "streak",
                displayName: "Logging Streak",
                supportedFamilies: CLKComplicationFamily.allCases
            ),
            CLKComplicationDescriptor(
                identifier: "medications",
                displayName: "Next Medication",
                supportedFamilies: CLKComplicationFamily.allCases
            )
        ]

        handler(descriptors)
    }

    // MARK: - Timeline Configuration

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Update complications hourly
        handler(Date().addingTimeInterval(60 * 60))
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let connectivity = WatchConnectivityService.shared
        let entry: CLKComplicationTimelineEntry?

        switch complication.identifier {
        case "todayCount":
            entry = createTodayCountEntry(complication: complication, count: connectivity.todayLogCount)
        case "streak":
            entry = createStreakEntry(complication: complication, streak: connectivity.streakCount)
        case "medications":
            entry = createMedicationEntry(complication: complication, medications: connectivity.upcomingMedications)
        default:
            entry = createTodayCountEntry(complication: complication, count: connectivity.todayLogCount)
        }

        handler(entry)
    }

    // MARK: - Sample Templates

    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template: CLKComplicationTemplate?

        switch complication.family {
        case .modularSmall:
            template = createModularSmallTemplate(count: 5)
        case .modularLarge:
            template = createModularLargeTemplate(count: 5, streak: 7)
        case .utilitarianSmall:
            template = createUtilitarianSmallTemplate(count: 5)
        case .utilitarianLarge:
            template = createUtilitarianLargeTemplate(count: 5)
        case .circularSmall:
            template = createCircularSmallTemplate(count: 5)
        case .graphicCorner:
            template = createGraphicCornerTemplate(count: 5, streak: 7)
        case .graphicCircular:
            template = createGraphicCircularTemplate(count: 5)
        case .graphicRectangular:
            template = createGraphicRectangularTemplate(count: 5, streak: 7)
        case .graphicBezel:
            template = createGraphicBezelTemplate(count: 5)
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                template = createGraphicExtraLargeTemplate(count: 5)
            } else {
                template = nil
            }
        default:
            template = nil
        }

        handler(template)
    }

    // MARK: - Helper Methods

    private func createTodayCountEntry(complication: CLKComplication, count: Int) -> CLKComplicationTimelineEntry {
        let template: CLKComplicationTemplate

        switch complication.family {
        case .modularSmall:
            template = createModularSmallTemplate(count: count)
        case .modularLarge:
            template = createModularLargeTemplate(count: count, streak: WatchConnectivityService.shared.streakCount)
        case .circularSmall:
            template = createCircularSmallTemplate(count: count)
        case .graphicCircular:
            template = createGraphicCircularTemplate(count: count)
        case .graphicRectangular:
            template = createGraphicRectangularTemplate(count: count, streak: WatchConnectivityService.shared.streakCount)
        default:
            template = createModularSmallTemplate(count: count)
        }

        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }

    private func createStreakEntry(complication: CLKComplication, streak: Int) -> CLKComplicationTimelineEntry {
        let template = createGraphicCircularTemplate(count: streak)
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }

    private func createMedicationEntry(complication: CLKComplication, medications: [[String: Any]]) -> CLKComplicationTimelineEntry {
        let count = medications.filter { ($0["taken"] as? Bool) == false }.count
        let template = createGraphicCircularTemplate(count: count)
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }

    // MARK: - Template Creation

    private func createModularSmallTemplate(count: Int) -> CLKComplicationTemplateModularSmallStackText {
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "\(count)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "today")
        return template
    }

    private func createModularLargeTemplate(count: Int, streak: Int) -> CLKComplicationTemplateModularLargeStandardBody {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Behavior Tracker")
        template.body1TextProvider = CLKSimpleTextProvider(text: "\(count) entries today")
        template.body2TextProvider = CLKSimpleTextProvider(text: "\(streak) day streak")
        return template
    }

    private func createUtilitarianSmallTemplate(count: Int) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: "\(count) today")
        return template
    }

    private func createUtilitarianLargeTemplate(count: Int) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "Behavior: \(count) today")
        return template
    }

    private func createCircularSmallTemplate(count: Int) -> CLKComplicationTemplateCircularSmallStackText {
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "\(count)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "log")
        return template
    }

    private func createGraphicCornerTemplate(count: Int, streak: Int) -> CLKComplicationTemplateGraphicCornerStackText {
        let template = CLKComplicationTemplateGraphicCornerStackText()
        template.outerTextProvider = CLKSimpleTextProvider(text: "\(count) today")
        template.innerTextProvider = CLKSimpleTextProvider(text: "\(streak) streak")
        return template
    }

    private func createGraphicCircularTemplate(count: Int) -> CLKComplicationTemplateGraphicCircularStackText {
        let template = CLKComplicationTemplateGraphicCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "\(count)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "today")
        return template
    }

    private func createGraphicRectangularTemplate(count: Int, streak: Int) -> CLKComplicationTemplateGraphicRectangularStandardBody {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Behavior Tracker")
        template.body1TextProvider = CLKSimpleTextProvider(text: "\(count) entries")
        template.body2TextProvider = CLKSimpleTextProvider(text: "\(streak) day streak")
        return template
    }

    private func createGraphicBezelTemplate(count: Int) -> CLKComplicationTemplateGraphicBezelCircularText {
        let circular = createGraphicCircularTemplate(count: count)
        let template = CLKComplicationTemplateGraphicBezelCircularText()
        template.circularTemplate = circular
        template.textProvider = CLKSimpleTextProvider(text: "entries today")
        return template
    }

    @available(watchOS 7.0, *)
    private func createGraphicExtraLargeTemplate(count: Int) -> CLKComplicationTemplateGraphicExtraLargeCircularStackText {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "\(count)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "entries")
        return template
    }
}
