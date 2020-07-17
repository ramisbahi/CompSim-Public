import UIKit

var str = "Hello, playground"
var minFontSize: CGFloat = 1.0 // CGFloat 18
var maxFontSize: CGFloat = 300.0     // CGFloat 67
var currentFontSize: CGFloat = (minFontSize + maxFontSize ) / 2

let target = 95

while abs(maxFontSize - minFontSize) > 0.5
{
    if Float(target) < Float(currentFontSize)
    {
        maxFontSize = currentFontSize
    }
    else if Float(target) > Float(currentFontSize)
    {
        minFontSize = currentFontSize
    }
    else
    {
        print("found it: \(currentFontSize)")
        break
    }
    
    currentFontSize = (minFontSize + maxFontSize ) / 2
}


print(currentFontSize)
