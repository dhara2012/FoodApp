import SwiftUI

/// ઉપર ચોંટેલો search bar (iOS ના floating .searchable ની જગ્યાએ),
/// જેથી નીચેના "View Cart" bar સાથે ટકરાય નહીં
struct SearchBar: View {
    @Binding var text: String
    var prompt: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
