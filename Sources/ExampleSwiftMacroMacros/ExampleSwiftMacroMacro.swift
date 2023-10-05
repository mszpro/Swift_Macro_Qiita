import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftCompilerPlugin
import Foundation
import SwiftUI

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct URLMacro: ExpressionMacro {
    
    enum URLMacroError: Error {
        case missingArgument
        case argumentNotString
        case invalidURL
        case invalidURL_Scheme
        case invalidURL_Host
    }
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            context.diagnose(CodingKeysMacroDiagnostic.missingArgument.diagnose(at: node))
            throw URLMacroError.missingArgument
        }
        
        guard let stringLiteralExpr = argument.as(StringLiteralExprSyntax.self),
              let segment = stringLiteralExpr.segments.first?.as(StringSegmentSyntax.self),
              stringLiteralExpr.segments.count == 1
        else {
            context.diagnose(CodingKeysMacroDiagnostic.argumentNotString.diagnose(at: node))
            throw URLMacroError.argumentNotString
        }
        
        let text = segment.content.text
        
        guard let url = URL(string: text) else {
            context.diagnose(CodingKeysMacroDiagnostic.invalidURL.diagnose(at: node))
            throw URLMacroError.invalidURL
        }
        
        guard let scheme = url.scheme,
              ["http", "https"].contains(scheme) else {
            context.diagnose(CodingKeysMacroDiagnostic.invalidURL_Scheme(url.scheme ?? "?").diagnose(at: node))
            throw URLMacroError.invalidURL_Scheme
        }
        
        guard let host = url.host,
              !host.isEmpty else {
            context.diagnose(CodingKeysMacroDiagnostic.invalidURL_Host.diagnose(at: node))
            throw URLMacroError.invalidURL_Host
        }
        
        return #"URL(string: "\#(raw: text)")!"#
    }
    
}

public struct SwiftUISystemImageMacro: ExpressionMacro {
    
    enum SFSymbolMacroError: Error {
        case missingArgument
        case argumentNotString
        case invalidSFSymbolName
    }
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            throw SFSymbolMacroError.missingArgument
        }
        
        guard let stringLiteralExpr = argument.as(StringLiteralExprSyntax.self),
              let segment = stringLiteralExpr.segments.first?.as(StringSegmentSyntax.self),
              stringLiteralExpr.segments.count == 1
        else {
            throw SFSymbolMacroError.argumentNotString
        }
        
        let text = segment.content.text
        
        #if os(iOS)
        guard UIImage(systemName: text) != nil else {
            throw SFSymbolMacroError.invalidSFSymbolName
        }
        #elseif os(macOS)
        guard NSImage(systemSymbolName: text, accessibilityDescription: nil) != nil else {
            throw SFSymbolMacroError.invalidSFSymbolName
        }
        #endif
        
        return #"Image(systemName: "\#(raw: text)")"#
    }
}


@main
struct ExampleSwiftMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        URLMacro.self,
        SwiftUISystemImageMacro.self,
        NSUbiquitousKeyValueStoreMacro.self
    ]
}

private extension AttachedMacro {
    static func getAttributes(
        _ attributes: AttributeListSyntax?,
        _ key: String
    ) -> AttributeSyntax? {
        attributes?
            .first(where: { "\($0)".contains(key) })?
            .as(AttributeSyntax.self)
    }
    
    static func getModifiers(
        _ initialModifiers: String,
        _ modifiers: DeclModifierListSyntax?
    ) -> String {
        var initialModifiers = initialModifiers
        modifiers?.forEach {
            if let accessorType = $0.as(DeclModifierSyntax.self)?.name {
                initialModifiers += "\(accessorType.text) "
            }
        }
        return initialModifiers
    }
}

public struct NSUbiquitousKeyValueStoreMacro: AccessorMacro {
    
    enum NSUbiquitousKeyValueStoreMacroError: Error {
        case noTypeDefined
        case cannotGetBinding
        case cannotGetVariableName
    }
    
    public static func expansion(of node: AttributeSyntax,
                                 providingAccessorsOf declaration: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        
        let typeAttribute = node.attributeName.as(IdentifierTypeSyntax.self)
        guard let dataType = typeAttribute?.type else {
            throw NSUbiquitousKeyValueStoreMacroError.noTypeDefined
        }
        
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            return []
        }
        
        guard let binding = varDecl.bindings.first?.as(PatternBindingSyntax.self)else {
            throw NSUbiquitousKeyValueStoreMacroError.cannotGetBinding
        }
        
        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw NSUbiquitousKeyValueStoreMacroError.cannotGetVariableName
        }
        
        var defaultValue = ""
        if let value = binding.initializer?.value {
            defaultValue = " ?? \(value)"
        }
        
        let getAccessor: AccessorDeclSyntax =
          """
          get {
              (NSUbiquitousKeyValueStore.default.object(forKey: "\(raw: identifier)") as? \(raw: dataType))\(raw: defaultValue)
          }
          """
        
        let setAccessor: AccessorDeclSyntax =
          """
          set {
              NSUbiquitousKeyValueStore.default.set(newValue, forKey: "\(raw: identifier)")
          }
          """
        return [getAccessor, setAccessor]
    }
    
}

extension IdentifierTypeSyntax {
    var type: SyntaxProtocol? {
        genericArgumentClause?.arguments.first?.as(GenericArgumentSyntax.self)?.argument.as(OptionalTypeSyntax.self)?.wrappedType
        ?? genericArgumentClause?.arguments.first?.as(GenericArgumentSyntax.self)
    }
}
