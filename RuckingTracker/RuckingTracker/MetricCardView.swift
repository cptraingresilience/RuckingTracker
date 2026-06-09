//
//  MetricCardView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let unit: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(value).bold().font(.title2)
            if let unit = unit {
                Text(unit).font(.subheadline)
            }
        }
        .frame(width: 110, height: 60)
        .background(Color.gray.opacity(0.13))
        .cornerRadius(8)
    }
}


