import SwiftUI

struct DirectoryListRow<LeadingContent: View, TitleAccessory: View, TrailingContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled = true
    @State private var isHovered = false

    let name: String
    let path: String
    let verticalInset: CGFloat
    let onOpen: () -> Void
    private let leadingContent: () -> LeadingContent
    private let titleAccessory: () -> TitleAccessory
    private let trailingContent: () -> TrailingContent

    init(
        name: String,
        path: String,
        verticalInset: CGFloat = PageListMetrics.rowVerticalInset,
        onOpen: @escaping () -> Void,
        @ViewBuilder leadingContent: @escaping () -> LeadingContent,
        @ViewBuilder titleAccessory: @escaping () -> TitleAccessory,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.name = name
        self.path = path
        self.verticalInset = verticalInset
        self.onOpen = onOpen
        self.leadingContent = leadingContent
        self.titleAccessory = titleAccessory
        self.trailingContent = trailingContent
    }

    var body: some View {
        HStack(alignment: .center, spacing: PageListMetrics.itemSpacing) {
            leadingContent()

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center) {
                    Text(name)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                        .font(.title3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(name)
                        .overlay {
                            if isHovered {
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(ThemeColors.shared(for: colorScheme).primaryText.opacity(0.5))
                                        .frame(height: 1.5)
                                        .offset(y: 3)
                                }
                            }
                        }

                    titleAccessory()
                }

                path.pathWithArrows(separatorColor: ThemeColors.shared(for: colorScheme).primaryText)
                    .font(.footnote)
                    .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    .help(path)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: animationEnabled ? 0.35 : 0)) {
                    isHovered = hovering
                }
            }

            Spacer(minLength: PageListMetrics.itemSpacing)
            trailingContent()
        }
        .padding(.vertical, verticalInset)
    }
}
