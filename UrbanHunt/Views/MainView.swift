//
//  MainView.swift
//  UrbanHunt
//
//  Main authenticated view
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        HomeView()
            .environmentObject(authViewModel)
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
}