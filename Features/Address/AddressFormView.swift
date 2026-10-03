import SwiftUI

struct AddressFormView: View {
    @StateObject var viewModel: AddressFormViewModel
    @EnvironmentObject var book: AddressBook
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.useCurrentLocation() }
                } label: {
                    HStack {
                        if viewModel.isLocating { ProgressView() } else { Image(systemName: "location.fill") }
                        Text(viewModel.isLocating ? "Fetching location…" : "Use current location")
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLocating)

                if let error = viewModel.locationError {
                    Text(error).font(.caption).foregroundColor(.red)
                }
                if let lat = viewModel.latitude, let lng = viewModel.longitude {
                    Text(String(format: "📍 Lat %.5f, Long %.5f", lat, lng))
                        .font(.caption).foregroundColor(.secondary)
                }

                FormField(title: "Full name", text: $viewModel.name, error: viewModel.errors[.name], contentType: .name)
                FormField(title: "Mobile number", text: $viewModel.mobile, error: viewModel.errors[.mobile],
                          keyboard: .numberPad, contentType: .telephoneNumber)
                FormField(title: "House / Flat no.", text: $viewModel.house, error: viewModel.errors[.house])
                FormField(title: "Area", text: $viewModel.area, error: viewModel.errors[.area])
                FormField(title: "City", text: $viewModel.city, error: viewModel.errors[.city])
                FormField(title: "State", text: $viewModel.state, error: viewModel.errors[.state])
                FormField(title: "Pincode", text: $viewModel.pincode, error: viewModel.errors[.pincode],
                          keyboard: .numberPad, contentType: .postalCode)

                Toggle("Make this my default address", isOn: $viewModel.isDefault)

                PrimaryButton(title: viewModel.isEditing ? "Update address" : "Save address") {
                    guard let address = viewModel.build() else { return }
                    if viewModel.isEditing { book.update(address) } else { book.add(address) }
                    dismiss()
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.isEditing ? "Edit address" : "Add address")
        .navigationBarTitleDisplayMode(.inline)
    }
}
