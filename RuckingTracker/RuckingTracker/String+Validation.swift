//
//  String+Validation.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import Foundation

extension String {
    var isEmail: Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    var isStrongPassword: Bool {
        self.count > 7
        && rangeOfCharacter(from: .uppercaseLetters) != nil
        && rangeOfCharacter(from: .decimalDigits) != nil
        && rangeOfCharacter(from: .symbols) != nil
    }
}
