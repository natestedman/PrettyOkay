// Copyright (c) 2017, Nate Stedman <nate@natestedman.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.

import CoreGraphics

extension CGSize
{
    static var greatestFiniteMagnitude: CGSize
    {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    /// Returns a rect that fits the receiver, centered in `rect`.
    ///
    /// - parameter rect: The rect to center in.
    func centered(in rect: CGRect) -> CGRect
    {
        return CGRect(
            origin: CGPoint(x: rect.midX - width / 2, y: rect.midY - height / 2),
            size: self
        )
    }

    /// Returns a size that fits the receiver within `size`, while maintaining the receiver's aspect ratio.
    ///
    /// - parameter size: The size to fit in.
    func fit(in size: CGSize) -> CGSize
    {
        if width > size.width || height > size.height
        {
            let scale = min(size.width / width, size.height / height)
            return CGSize(width: width * scale, height: height * scale)
        }
        else
        {
            return self
        }
    }

    /// Returns a rect that fits and centers the receiver in `rect`, while maintaining the receiver's aspect ratio.
    ///
    /// - parameter rect: The rect to fit and center in.
    func fit(in rect: CGRect) -> CGRect
    {
        return fit(in: rect.size).centered(in: rect)
    }

    /// Rounds the size's `width` and `height`.
    func rounded() -> CGSize
    {
        return CGSize(width: round(width), height: round(height))
    }
}

extension CGPoint
{
    /// Rounds the point's `x` and `y` coordinates.
    func rounded() -> CGPoint
    {
        return CGPoint(x: round(x), y: round(y))
    }
}

extension CGRect
{
    /// Rounds the rect's `origin`.
    func roundedOrigin() -> CGRect
    {
        return CGRect(origin: origin.rounded(), size: size)
    }
}
