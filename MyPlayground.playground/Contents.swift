import UIKit
import JavaScriptCore

var str = "Hello, playground"

let scramble_444_url = Bundle.main.url(forResource: "scramble_444", withExtension: "js")

let jsContext: JSContext = JSContext.init()
jsContext.evaluateScript("scramble_444.getRandomScramble()", withSourceURL: scramble_444_url)
