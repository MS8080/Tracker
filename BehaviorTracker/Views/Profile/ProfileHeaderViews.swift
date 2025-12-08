import SwiftUI

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    let profile: UserProfile?
    let onEditTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if let profileImage = profile?.profileImage {
                    #if os(iOS)
                    Image(uiImage: profileImage)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    #elseif os(macOS)
                    Image(nsImage: profileImage)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    #endif
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(profile?.initials ?? "?")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                }

                Circle()
                    .fill(.blue)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 36, y: 36)
            }
            .contentShape(Circle())
            .onTapGesture { onEditTapped() }
            .modifier(DisableGlassEffectModifier())

            VStack(spacing: 6) {
                Text(profile?.name ?? "User")
                    .font(.title)
                    .fontWeight(.bold)

                if let email = profile?.email, !email.isEmpty {
                    Text(email)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                if let age = profile?.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Demo Profile Header Section

struct DemoProfileHeaderSection: View {
    let name: String
    let email: String?

    private var initials: String {
        let parts = name.components(separatedBy: " ")
        let firstInitial = parts.first?.first.map(String.init) ?? ""
        let lastInitial = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return "\(firstInitial)\(lastInitial)"
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    )
                    .overlay(Circle().stroke(Color.orange, lineWidth: 3))
            }
            .modifier(DisableGlassEffectModifier())

            VStack(spacing: 6) {
                Text(name)
                    .font(.title)
                    .fontWeight(.bold)

                if let email = email, !email.isEmpty {
                    Text(email)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
