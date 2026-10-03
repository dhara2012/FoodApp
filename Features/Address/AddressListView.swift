import SwiftUI

/// onSelect આપો તો "સરનામું પસંદ કરો" mode (Home/Checkout), નહીંતર manage mode (Profile)
struct AddressListView: View {
    @EnvironmentObject var book: AddressBook
    var onSelect: ((Address) -> Void)? = nil

    @State private var formAddress: Address?
    @State private var showForm = false
    @State private var pendingDelete: Address?

    var body: some View {
        List {
            if book.addresses.isEmpty {
                VStack(spacing: 8) {
                    Text("📍").font(.system(size: 44))
                    Text("No saved addresses").font(.headline)
                    Text("Add an address to get your food delivered").font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
                .listRowBackground(Color.clear)
            }
            ForEach(book.addresses) { address in
                Button {
                    if let onSelect { onSelect(address) } else { open(address) }
                } label: { row(address) }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) { pendingDelete = address }
                    Button("Edit") { open(address) }.tint(.blue)
                }
                .swipeActions(edge: .leading) {
                    if !address.isDefault {
                        Button("Set default") { book.setDefault(id: address.id) }.tint(.green)
                    }
                }
            }
        }
        .navigationTitle(onSelect == nil ? "Saved addresses" : "Select address")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { open(nil) } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showForm) {
            NavigationStack { AddressFormView(viewModel: AddressFormViewModel(address: formAddress)) }
        }
        .alert("Delete address?", isPresented: Binding(get: { pendingDelete != nil },
                                                        set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let a = pendingDelete { book.delete(id: a.id) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(pendingDelete?.oneLine ?? "")
        }
    }

    private func open(_ address: Address?) {
        formAddress = address
        showForm = true
    }

    private func row(_ a: Address) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(a.name).font(.headline)
                    if a.isDefault {
                        Text("DEFAULT").font(.caption2.bold()).foregroundColor(.green)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green.opacity(0.15)).clipShape(Capsule())
                    }
                }
                Text(a.oneLine).font(.subheadline).foregroundColor(.secondary)
                Text("📞 \(a.mobile)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if onSelect != nil && book.selectedAddress?.id == a.id {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Home ના ઉપરનું "Deliver to ..." બટન
struct AddressHeaderButton: View {
    @EnvironmentObject var book: AddressBook
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            VStack(spacing: 0) {
                Text("Deliver to").font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Text("📍")
                    Text(book.selectedAddress.map { "\($0.area), \($0.city)" } ?? "Add address")
                        .font(.subheadline.bold()).lineLimit(1)
                    Image(systemName: "chevron.down").font(.caption2)
                }
            }
            .foregroundColor(.primary)
        }
        .sheet(isPresented: $show) {
            NavigationStack {
                AddressListView { address in
                    book.select(address.id)
                    show = false
                }
            }
        }
    }
}
