//
//  RadialColorPalete.swift
//  FlexColorPicker
//
//  Created by Rastislav Mirek on 27/5/18.
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

import UIKit

open class RadialColorPalete: ColorPalete {
    public private(set) var diameter: CGFloat = 0
    public private(set) var radius: CGFloat = 0
    public private(set) var midX: CGFloat = 0
    public private(set) var midY: CGFloat = 0
    private(set) var ceiledDiameter: Int = 0

    open var size: CGSize = .zero {
        didSet {
            let diameter = min(size.width, size.height)
            self.diameter = diameter
            self.radius = diameter / 2
            self.midX = diameter / 2 + min(0, (size.width - diameter) / 2)
            self.midY = diameter / 2 + min(0, (size.height - diameter) / 2)
            self.ceiledDiameter = Int(ceil(diameter))
        }
    }

    @inline(__always)
    open func hueAndSaturation(at point: CGPoint) -> (hue: CGFloat, saturation: CGFloat, alpha: CGFloat) {
        let dy = (point.y - midY) / radius
        let dx = (point.x - midX) / radius
        let distance = sqrt(dx * dx + dy * dy)
        if distance <= 0 {
            return (0, 0, 1)
        }
        let hue = acos(dx / distance) / CGFloat.pi / 2
        if abs(distance * radius - 117) <= 0.01 && dy > 0 {
            print(dx, dy, hue, dx < 0 ? 1 + hue : hue)
        }
        return (dy < 0 ? 1 - hue : hue, min(1, distance), distance > 1 ? 0 : 1)
    }

    open func renderForegroundImage() -> UIImage {
        var imageData = [UInt8](repeating: 255, count: (4 * ceiledDiameter * ceiledDiameter))
        for i in 0 ..< ceiledDiameter {
            for j in 0 ..< ceiledDiameter {
                let index = 4 * (i * ceiledDiameter + j)
                let (hue, saturation, _) = hueAndSaturation(at: CGPoint(x: i, y: j))
                let (r, g, b) = rgbFrom(hue: hue, saturation: saturation)
                imageData[index] = colorComponentToUInt8(r)
                imageData[index + 1] = colorComponentToUInt8(g)
                imageData[index + 2] = colorComponentToUInt8(b)
                imageData[index + 3] = 255
            }
        }

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let data = Data(bytes: imageData)
        let mutableData = UnsafeMutableRawPointer.init(mutating: (data as NSData).bytes)
        let context = CGContext(data: mutableData, width: ceiledDiameter, height: ceiledDiameter, bitsPerComponent: 8, bytesPerRow: 4 * ceiledDiameter, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)
        guard let cgImage = context?.makeImage() else {
            return UIImage()
        }

        // clip the image to circle
        let imageRect = CGRect(x: 0,y: 0, width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIBezierPath(ovalIn: imageRect).addClip()
        UIImage(cgImage: cgImage).draw(in: imageRect)
        defer {
            UIGraphicsEndImageContext()
        }
        if let clippedImage = UIGraphicsGetImageFromCurrentImageContext() {
            return clippedImage
        }
        return UIImage()
    }

    open func renderBackgroundImage() -> UIImage {
        let imageRect = CGRect(x: 0,y: 0, width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIBezierPath(ovalIn: imageRect).addClip()
        UIColor.black.setFill()
        defer {
            UIGraphicsEndImageContext()
        }
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return UIImage()
    }

    open func closestPoint(to point: CGPoint) -> CGPoint {
        let distance = point.distanceTo(x: midX, y: midY)
        if distance <= diameter {
            return point
        }
        let x = midX + radius * ((point.x - midX) / distance)
        let y = midY + radius * ((point.y - midY) / distance)
        return CGPoint(x: x, y: y)
    }
}