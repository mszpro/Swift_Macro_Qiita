import ExampleSwiftMacro
import Foundation
import SwiftUI

let a = 17
let b = 25

let (result, code) = #stringify(a + b)
print("The value \(result) was produced by the code \"\(code)\"")

let goodURL = #urlFromString("https://apple.com")
print(goodURL.host ?? "")
//
let badURL = #urlFromString("ftp://www.apple.com")
print(badURL.host ?? badURL)

let image = #systemImage("calendar")

let badImage = #systemImage("dragon")

@iCloudKeyValue<String>
var userCity: String = "Tokyo"
