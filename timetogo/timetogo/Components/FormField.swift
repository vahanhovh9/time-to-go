import SwiftUI

/// Labelled grey field used across setup (Figma: "Dropdown").
/// 14pt label above a 48pt grey box with Element corners with a trailing chevron.
/// Outlined white instead when `formFieldOutlined` is set (setup cards).
struct FormField<Value: View>: View {
    var label: String
    var action: () -> Void
    @ViewBuilder var value: () -> Value

    @Environment(\.formFieldOutlined) private var isOutlined

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .typography(.main)
                .foregroundColor(.black)

            Button(action: action) {
                HStack(spacing: 12) {
                    value()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .scaledFont(size: 15, weight: .semibold)
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .background(isOutlined ? Color.white : Color.grey10)
                .clipShape(RoundedRectangle(cornerRadius: Radius.element))
                .overlay {
                    if isOutlined {
                        RoundedRectangle(cornerRadius: Radius.element).strokeBorder(Color.grey29, lineWidth: 1)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: Radius.element))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        }
    }
}

private struct FormFieldOutlinedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var formFieldOutlined: Bool {
        get { self[FormFieldOutlinedKey.self] }
        set { self[FormFieldOutlinedKey.self] = newValue }
    }
}

/// Field value text: grey "Choose" placeholder, black once something is picked.
struct FormFieldValue: View {
    var text: String
    var isPlaceholder: Bool

    var body: some View {
        Text(text)
            .typography(.h4)
            .foregroundColor(isPlaceholder ? .grey50 : .black)
            .lineLimit(1)
    }
}

#Preview {
    VStack(spacing: 38) {
        FormField(label: "Home station", action: {}) {
            FormFieldValue(text: "Choose", isPlaceholder: true)
        }
        FormField(label: "How long is your walk to the tube?", action: {}) {
            FormFieldValue(text: "5 min", isPlaceholder: false)
        }
    }
    .padding(24)
}
