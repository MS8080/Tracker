import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let dataController: DataController
    @Binding var profile: UserProfile?

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var hasDateOfBirth: Bool = false
    @State private var selectedImage: PlatformImage?
    @State private var showImagePicker: Bool = false
    #if os(iOS)
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    #endif
    @State private var showImageSourcePicker: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        profileImageView
                            .onTapGesture {
                                showImageSourcePicker = true
                            }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } footer: {
                    Text("Tap to change photo")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Personal Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif

                    Toggle("Date of Birth", isOn: $hasDateOfBirth)

                    if hasDateOfBirth {
                        DatePicker(
                            "Birthday",
                            selection: $dateOfBirth,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                .hideSharedBackground()

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .disabled(name.isEmpty)
                }
                .hideSharedBackground()
            }
            .onAppear {
                loadProfile()
            }
            #if os(iOS)
            .confirmationDialog("Choose Photo Source", isPresented: $showImageSourcePicker) {
                Button("Camera") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
                Button("Photo Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imageSourceType)
            }
            #endif
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        ZStack {
            #if os(iOS)
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let profileImage = profile?.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    )
            }
            #elseif os(macOS)
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let profileImage = profile?.profileImage {
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    )
            }
            #endif
        }
        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
    }

    private func loadProfile() {
        if let p = profile {
            name = p.name
            email = p.email ?? ""
            if let dob = p.dateOfBirth {
                dateOfBirth = dob
                hasDateOfBirth = true
            }
        }
    }

    private func saveProfile() {
        guard let p = profile else { return }

        p.name = name
        p.email = email.isEmpty ? nil : email
        p.dateOfBirth = hasDateOfBirth ? dateOfBirth : nil

        if let image = selectedImage {
            let resizedImage = image.resized(toMaxDimension: 500)
            p.profileImage = resizedImage
        }

        dataController.updateUserProfile(p)

        // Notify other views that profile was updated
        NotificationCenter.default.post(name: .profileUpdated, object: nil)
    }
}

// MARK: - Image Picker

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#Preview {
    EditProfileView(dataController: DataController.shared, profile: .constant(nil))
}
