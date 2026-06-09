//
//  LoginView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 80)
            
            Text("Rux")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 12)

            TextField("Username or Email", text: $viewModel.username)
                .padding()
                .background(Color.blue.opacity(0.12))
                .cornerRadius(10)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)
            
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color.blue.opacity(0.12))
                .cornerRadius(10)
                .padding(.horizontal)

            Button(action: { viewModel.loginWithEmail() }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .disabled(viewModel.isLoading)

            Divider().padding(.horizontal)

            // Changed: No longer using a sheet.
            // Just call the function directly.
            Button(action: {
                // Get the root view controller from the window
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    viewModel.loginWithGoogle(presenting: rootVC)
                }
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Continue with Google")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            TabViewMain()
        }
    }
}

// You’ll need to implement a simple GoogleSignInView
struct GoogleSignInView: UIViewControllerRepresentable {
    var completion: (UIViewController) -> Void
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            completion(vc)
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

