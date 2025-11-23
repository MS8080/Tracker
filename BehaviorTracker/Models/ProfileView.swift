import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#endif

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var dataController: DataController

    @State private var profile: UserProfile?
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var hasDateOfBirth: Bool = false

    // Image picker states
    @State private var showImagePicker: Bool = false
    @State private var showImageSourcePicker: Bool = false
    @State private var selectedImage: PlatformImage?
    #if os(iOS)
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    #endif

    @State private var showSaveConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Image Section
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
                } header: {
                    Text("Profile Photo")
                } footer: {
                    Text("Tap to change your profile picture")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Personal Information Section
                Section("Personal Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                        .autocorrectionDisabled()
                    
                    Toggle("Date of Birth", isOn: $hasDateOfBirth)
                    
                    if hasDateOfBirth {
                        DatePicker(
                            "Birthday",
                            selection: $dateOfBirth,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                }
                
                // Profile Stats Section
                if let profile = profile {
                    Section("Profile Info") {
                        LabeledContent("Member Since") {
                            Text(profile.createdAt, style: .date)
                        }
                        
                        if let age = profile.age {
                            LabeledContent("Age") {
                                Text("\(age) years old")
                            }
                        }
                    }
                }
                
                // Actions Section
                Section {
                    Button("Save Profile") {
                        saveProfile()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty)
                    
                    if selectedImage != nil || profile?.hasProfileImage == true {
                        Button("Remove Photo", role: .destructive) {
                            selectedImage = nil
                            profile?.profileImage = nil
                            dataController.save()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Profile")
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
                ImagePicker(
                    image: $selectedImage,
                    sourceType: imageSourceType
                )
            }
            #endif
            .alert("Profile Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your profile has been updated successfully.")
            }
        }
    }
    
    // MARK: - Profile Image View
    
    @ViewBuilder
    private var profileImageView: some View {
        ZStack {
            #if os(iOS)
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else if let profileImage = profile?.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                placeholderCircle
            }
            #elseif os(macOS)
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else if let profileImage = profile?.profileImage {
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                placeholderCircle
            }
            #endif

            // Camera overlay
            Circle()
                .fill(Color.black.opacity(0.4))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                )
                .opacity(0.0)
                .animation(.easeInOut, value: showImageSourcePicker)
        }
        .overlay(
            Circle()
                .stroke(Color.blue, lineWidth: 3)
        )
        .shadow(radius: 5)
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
                Text(profile?.initials ?? "?")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            )
    }
    
    // MARK: - Methods
    
    private func loadProfile() {
        profile = dataController.getOrCreateUserProfile()
        
        if let profile = profile {
            name = profile.name
            email = profile.email ?? ""
            if let dob = profile.dateOfBirth {
                dateOfBirth = dob
                hasDateOfBirth = true
            }
        }
    }
    
    private func saveProfile() {
        guard let profile = profile else { return }
        
        profile.name = name
        profile.email = email.isEmpty ? nil : email
        profile.dateOfBirth = hasDateOfBirth ? dateOfBirth : nil
        
        if let image = selectedImage {
            // Resize image to save storage
            let resizedImage = image.resized(toMaxDimension: 500)
            profile.profileImage = resizedImage
        }
        
        dataController.updateUserProfile(profile)
        showSaveConfirmation = true
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

// MARK: - Preview

#Preview {
    ProfileView(dataController: DataController.shared)
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}
