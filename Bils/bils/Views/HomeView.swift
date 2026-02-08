import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: PaymentStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                Text("Latest transactions")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                transactionsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 18)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
        .onAppear {
            seedPaymentsIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("bils")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.black)

                WaveUnderline()
                    .stroke(Color(red: 0.98, green: 0.29, blue: 0.21), lineWidth: 4)
                    .frame(width: 110, height: 10)
                    .padding(.leading, 2)
            }
        }
    }

    private var transactionsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, item in
                NavigationLink(value: AppDestination.split(paymentID: item.id)) {
                    TransactionRow(item: item)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if index < transactions.count - 1 {
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var transactions: [MockTransaction] {
        store.payments.map { payment in
            MockTransaction(
                id: payment.id,
                merchant: payment.merchant,
                location: "New York, NY",
                time: timeString(for: payment.date),
                amount: String(format: "$%.2f", payment.amount),
                icon: iconName(for: payment.category),
                iconBackground: iconBackground(for: payment.category),
                iconForeground: .white
            )
        }
    }

    private func seedPaymentsIfNeeded() {
        guard store.payments.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()
        let seeds: [(String, Double, PaymentCategory, Date)] = [
            ("Raising Cane's Chicken Fingers", 21.76, .restaurant, calendar.date(byAdding: .hour, value: -14, to: now) ?? now),
            ("Blue Bottle Coffee", 8.44, .restaurant, calendar.date(byAdding: .day, value: -1, to: now) ?? now),
            ("Metropolitan Transportation", 3.00, .utilities, calendar.date(byAdding: .day, value: -2, to: now) ?? now),
            ("Mojo East", 61.70, .restaurant, calendar.date(byAdding: .day, value: -3, to: now) ?? now),
            ("Metropolitan Transportation", 3.00, .utilities, calendar.date(byAdding: .day, value: -4, to: now) ?? now),
            ("CVS Pharmacy", 19.04, .other, calendar.date(byAdding: .day, value: -7, to: now) ?? now),
            ("Metropolitan Transportation", 3.00, .utilities, calendar.date(byAdding: .day, value: -7, to: now) ?? now),
            ("Blue Bottle Coffee", 8.44, .restaurant, calendar.date(byAdding: .day, value: -9, to: now) ?? now)
        ]

        for seed in seeds.reversed() {
            store.add(
                Payment(
                    merchant: seed.0,
                    amount: seed.1,
                    date: seed.3,
                    category: seed.2
                )
            )
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func iconName(for category: PaymentCategory) -> String {
        switch category {
        case .restaurant:
            return "fork.knife"
        case .groceries:
            return "cart.fill"
        case .utilities:
            return "bus.fill"
        case .entertainment:
            return "film.fill"
        case .other:
            return "heart.fill"
        }
    }

    private func iconBackground(for category: PaymentCategory) -> Color {
        switch category {
        case .restaurant:
            return Color(red: 0.91, green: 0.12, blue: 0.16)
        case .groceries:
            return Color(red: 0.22, green: 0.54, blue: 0.84)
        case .utilities:
            return Color(red: 0.31, green: 0.55, blue: 0.97)
        case .entertainment:
            return Color(red: 0.91, green: 0.60, blue: 0.36)
        case .other:
            return Color(red: 0.76, green: 0.16, blue: 0.14)
        }
    }
}
struct MockTransaction: Identifiable {
    let id: UUID
    let merchant: String
    let location: String
    let time: String
    let amount: String
    let icon: String
    let iconBackground: Color
    let iconForeground: Color
}

struct TransactionRow: View {
    let item: MockTransaction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.iconBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(item.iconForeground)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.merchant)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(item.amount)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                }

                Text(item.location)
                    .font(.caption)
                    .foregroundStyle(.gray)

                Text(item.time)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}

struct WaveUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amplitude: CGFloat = rect.height / 3
        let midY = rect.midY
        let width = rect.width
        let step = width / 6

        path.move(to: CGPoint(x: 0, y: midY))
        for i in 0...6 {
            let x = CGFloat(i) * step
            let y = i.isMultiple(of: 2) ? midY - amplitude : midY + amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
