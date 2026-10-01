//
//  LoginView.swift
//  Rux
// created on 9.26.26
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            // Background image: fills entire screen, anchored so the bottom of the image stays visible
            GeometryReader { geo in
                Image("LoginBackground2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                    .clipped()
                    .opacity(0.85)
                    .saturation(1.2)
            }
            .ignoresSafeArea()

            // Subtle overlay for depth
            Color.black.opacity(0.1)
                .edgesIgnoringSafeArea(.all)

            // Content
            VStack(spacing: 14) {
                Spacer()

                // Username / Email Field
                TextField("Username or Email", text: $viewModel.username)
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.blue.opacity(0.45))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 28)

                // Password Field
                SecureField("Password", text: $viewModel.password)
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.blue.opacity(0.45))
                    .cornerRadius(10)
                    .padding(.horizontal, 28)

                // Login Button — wired to real backend sign-in
                Button(action: { viewModel.loginWithEmail() }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal, 28)
                            .padding(.top, 6)
                    }
                }
                .disabled(viewModel.isLoading)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                // Divider with "or"
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.5))
                    Text("or")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                // 🌐 Social Login Buttons (visual only for now — backend handles email auth)
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.errorMessage = viewModel.socialSignInUnavailableMessage
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.teal]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .padding(.horizontal, 28)
                    }

                    Button(action: {
                        viewModel.errorMessage = viewModel.socialSignInUnavailableMessage
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.black)
                        .cornerRadius(10)
                        .padding(.horizontal, 28)
                    }
                }

                // Sign-up link (kept from current app)
                Button(action: { showSignUp = true }) {
                    Text("Don't have an account? ")
                        .foregroundColor(.white)
                    + Text("Create one")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)

                Spacer()
            }
            .padding(.bottom, 60)
        }
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            TabViewMain()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
