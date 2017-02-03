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

import UIKit

// MARK: - Loaded Images
final class LoadedImage: NSObject, NSCoding
{
    init(image: UIImage, originalSize: CGSize)
    {
        self.image = image
        self.originalSize = originalSize
    }

    // MARK: - Coding
    required init?(coder: NSCoder)
    {
        guard let image = coder.decodeObject(forKey: "image") as? UIImage else {
            return nil
        }

        self.image = image
        self.originalSize = coder.decodeCGSize(forKey: "originalSize")
    }

    func encode(with coder: NSCoder)
    {
        coder.encode(image, forKey: "image")
        coder.encode(originalSize, forKey: "originalSize")
    }

    // MARK: - Properties

    /// The image, which may have been scaled from its original dimensions.
    @nonobjc let image: UIImage

    /// The original size of the image.
    @nonobjc let originalSize: CGSize

    /// Checks equality with a second `LoadedImage`.
    ///
    /// - parameter other: The other image.
    override func isEqual(_ other: Any?) -> Bool
    {
        return (other as? LoadedImage).map({
            image == $0.image && originalSize == $0.originalSize
        }) ?? false
    }
}
