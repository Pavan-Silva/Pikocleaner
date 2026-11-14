import SwiftUI

struct PageHeaderView<Actions: View>: View {
    let title: String
    let description: String
    let leadingContent: AnyView?
    let actions: Actions

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        description: String,
        leadingContent: AnyView? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.description = description
        self.leadingContent = leadingContent
        self.actions = actions()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                if let leadingContent {
                    leadingContent
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 16)

            actions
                .buttonStyle(.plain)
                .controlGroup(Capsule(style: .continuous), level: .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PageListMetrics.horizontalInset)
        .padding(.bottom, 12)
    }
}

extension PageHeaderView where Actions == EmptyView {
    init(title: String, description: String) {
        self.init(title: title, description: description) {
            EmptyView()
        }
    }
}

struct PageHeaderActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .accessibilityLabel(Text(title))
            .font(.system(size: 16, weight: .medium))
            .frame(width: 20, height: 20)
            .padding(7)
    }
}
