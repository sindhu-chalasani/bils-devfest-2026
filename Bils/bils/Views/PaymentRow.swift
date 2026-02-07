import SwiftUI

struct PaymentRow: View {
    let payment: Payment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: payment.category.icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(payment.merchant)
                    .font(.subheadline.weight(.medium))
                Text(payment.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", payment.amount))
                    .font(.subheadline.weight(.semibold))
                Text(payment.splitStatus.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch payment.splitStatus {
        case .pending: return .orange
        case .splitEvenly: return .green
        case .customSplit: return .blue
        case .ignored: return .gray
        }
    }
}
