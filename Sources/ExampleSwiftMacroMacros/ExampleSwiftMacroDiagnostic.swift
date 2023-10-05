//
//  File.swift
//  
//
//  Created by Sora on 2023/10/05.
//

import Foundation
import SwiftSyntax
import SwiftDiagnostics

public enum CodingKeysMacroDiagnostic {
    case missingArgument
    case argumentNotString
    case invalidURL
    case invalidURL_Scheme(String)
    case invalidURL_Host
}

extension CodingKeysMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }
    
    public var message: String {
        switch self {
            case .missingArgument:
                return "You need to provide the argument in the parameter"
            case .argumentNotString:
                return "The argument you provided is not a String"
            case .invalidURL:
                return "Cannot initialize an URL from your provided string"
            case .invalidURL_Scheme(let scheme):
                return "\(scheme) is not a supported protocol"
            case .invalidURL_Host:
                return "The hostname of this URL is invalid"
        }
    }
    
    public var severity: DiagnosticSeverity { .error }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "CodingKeysMacro.\(self)")
    }
}
