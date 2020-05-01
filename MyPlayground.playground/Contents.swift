import UIKit

var str = "Hello, playground"

let timeFormatter = DateComponentsFormatter()

let timerTime: TimeInterval =  1.997

print(timeFormatter.string(from: timerTime)!)

timeFormatter.allowedUnits = [.hour, .minute, .second]
timeFormatter.unitsStyle = .positional
timeFormatter.zeroFormattingBehavior = .dropLeading

timeFormatter.string(from: timerTime)!
