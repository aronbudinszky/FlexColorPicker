//
//  RectangularHSBPalette.swift
//  FlexColorPicker
//
//  Created by Rastislav Mirek on 2/6/18.
//  
//	MIT License
//  Copyright (c) 2018 Rastislav Mirek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

class RectangularHSBPalette: ColorPalette {
    public var size: CGSize = .zero {
        didSet {
            intWidth = Int(size.width)
            intHeight = Int(size.height)
        }
    }
    public private(set) var intWidth = 0
    public private(set) var intHeight = 0

    @inline(__always)
    open func hueAndSaturation(at point: CGPoint) -> (hue: CGFloat, saturation: CGFloat) {
        return (max (0, min(1, point.x / size.width)), 1 - max(0, min(1, point.y / size.height)))
    }

    public func modifyColor(_ color: HSBColor, with point: CGPoint) -> HSBColor {
        let (hue, saturation) = hueAndSaturation(at: point)
        return color.withHue(hue, andSaturation: saturation)
    }

    open func renderForegroundImage() -> UIImage {
        var imageData = [UInt8](repeating: 255, count: (4 * intWidth * intHeight))
        for i in 0 ..< intWidth {
            for j in 0 ..< intHeight {
                let index = 4 * (i * intWidth + j)
                let (hue, saturation) = hueAndSaturation(at: CGPoint(x: j, y: i)) // rendering image transforms it as it it was mirrored around x = -y axis - adjusting for it by switching i and j here
                let (r, g, b) = rgbFrom(hue: hue, saturation: saturation, brightness: 1)
                imageData[index] = colorComponentToUInt8(r)
                imageData[index + 1] = colorComponentToUInt8(g)
                imageData[index + 2] = colorComponentToUInt8(b)
                imageData[index + 3] = 255
            }
        }
        return UIImage(rgbaBytes: imageData, width: intWidth, height: intHeight) ?? UIImage()
    }

    open func renderBackgroundImage() -> UIImage? {
        UIColor.black.setFill()
        return UIImage.drawImage(ofSize: size, path: UIBezierPath(rect: CGRect(origin: .zero, size: size)), fillColor: .black)
    }

    open func closestValidPoint(to point: CGPoint) -> CGPoint {
        return CGPoint(x: min(size.width, max(0, point.x)), y: min(size.height, max(0, point.y)))
    }

    open func positionAndAlpha(for color: HSBColor) -> (position: CGPoint, foregroundImageAlpha: CGFloat) {
        let (hue, saturation, brightness) = color.asTupleNoAlpha()
        return (CGPoint(x: hue * size.width, y: size.height - saturation * size.height), brightness)
    }
}