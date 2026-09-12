//
//  LoginView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSignUp = false

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 80)
            
            Text("Rux")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 12)

            TextField("Email", text: $viewModel.username)
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

            Text(viewModel.socialSignInUnavailableMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }

            Button(action: { showSignUp = true }) {
                Text("Don't have an account? ")
                    .foregroundColor(.primary)
                + Text("Create one")
                    .foregroundColor(.blue)
            }
            .font(.subheadline)
            .padding(.top, 4)

            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            TabViewMain()
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }
}
