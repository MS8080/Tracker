import SwiftUI

struct InsightsView: View {
    @Binding var showingProfile: Bool

    var body: some View {
        DailySummaryView(showingProfile: $showingProfile)
    }
}

#Preview {
    InsightsView(showingProfile: .constant(false))
}
