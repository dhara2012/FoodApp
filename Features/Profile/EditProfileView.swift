import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var services: ServiceContainer

    var body: some View {
        EditProfileContent(viewModel: EditProfileViewModel(user: profile.user, repository: services.profile))
    }
}

private struct EditProfileContent: View {
    @StateObject var viewModel: EditProfileViewModel
    @EnvironmentObject var profile: ProfileStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                FormField(title: "Full name", text: $viewModel.name, error: viewModel.errors["name"], contentType: .name)
                FormField(title: "Mobile number", text: $viewModel.mobile, error: viewModel.errors["mobile"],
                          keyboard: .numberPad, contentType: .telephoneNumber)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.email).padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground)).foregroundColor(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text("Email can't be changed").font(.caption).foregroundColor(.secondary)
                }

                if case .failure(let message) = viewModel.state {
                    Text(message).font(.footnote).foregroundColor(.red)
                }
                PrimaryButton(title: "Save changes", isLoading: viewModel.isSaving) {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.hasChanges)
            }
            .padding()
        }
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.$state) { state in
            if case .saved(let user) = state { profile.apply(user); dismiss() }
        }
    }
}
