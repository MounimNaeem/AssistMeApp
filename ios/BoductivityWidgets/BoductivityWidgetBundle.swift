import WidgetKit
import SwiftUI

@main
struct BoductivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayEventsWidget()
        DailyFitnessWidget()
    }
}
