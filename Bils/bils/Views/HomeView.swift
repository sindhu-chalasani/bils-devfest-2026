import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: PaymentStore
    @EnvironmentObject var notificationService: NotificationService

    @State private var merchant = ""
    @State private var amount = ""
    @State private var selectedCategory: PaymentCategory = .restaurant
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("bils")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Split payments, not friendships")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // "I just paid" card
                VStack(spacing: 16) {
                    Text("I just paid...")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Where? (e.g. Chipotle)", text: $merchant)
                        .textFieldStyle(.roundedBorder)

                    TextField("How much?", text: $amount)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)

                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PaymentCategory.allCases, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Label(category.rawValue, systemImage: category.icon)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category
                                                ? Color.blue
                                                : Color(.systemGray5)
                                        )
                                        .foregroundStyle(
                                            selectedCategory == category ? .white : .primary
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Button {
                        submitPayment()
                    } label: {
                        Text("I Paid")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSubmit ? Color.blue : Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canSubmit)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

                // Recent payments
                if !store.payments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent")
                                .font(.headline)
                            Spacer()
                            NavigationLink(value: AppDestination.history) {
                                Text("See all")
                                    .font(.subheadline)
                            }
                        }

                        ForEach(store.payments.prefix(3)) { payment in
                            PaymentRow(payment: payment)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                }

                // Test notification button (for development)
                Button {
                    notificationService.sendTestNotification()
                } label: {
                    Label("Send Test Notification", systemImage: "bell.badge")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            notificationService.requestPermission()
        }
        .overlay {
            if showConfirmation {
                confirmationOverlay
            }
        }
    }

    private var canSubmit: Bool {
        !merchant.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(amount) ?? 0) > 0
    }

    private func submitPayment() {
        guard let parsedAmount = Double(amount) else { return }

        let payment = Payment(
            merchant: merchant.trimmingCharacters(in: .whitespaces),
            amount: parsedAmount,
            category: selectedCategory
        )

        store.add(payment)
        notificationService.schedulePaymentNotification(payment: payment)

        // Reset form
        merchant = ""
        amount = ""
        selectedCategory = .restaurant

        // Brief confirmation
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showConfirmation = false }
        }
    }

    private var confirmationOverlay: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Payment logged!")
                .font(.headline)
            Text("You'll get a notification shortly")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }
}
