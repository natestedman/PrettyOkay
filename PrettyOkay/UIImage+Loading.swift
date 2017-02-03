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

import PINCache
import Result
import ReactiveSwift
import Shirley
import UIKit

// MARK: - Cache Sessions
extension UIImage
{
    /// The image cache - this contains both scaled and unscaled images.
    fileprivate static let cache = PINCache(name: "Images")

    /// A session to retrieve images from the network.
    fileprivate static let networkSession = URLSession.shared
        .httpResponse
        .raiseHTTPErrors()
        .body
        .flatMapValues(.concat, transform: { data in
            SignalProducer(result: Result(UIImage(data: data), failWith: ImageLoadingError.invalidData as NSError))
        })

    /// A session to cache network-loaded images locally.
    fileprivate static let imageSession: Session<URL, UIImage, NSError> = PINCacheSession(
        cache: cache,
        makeKey: { $0.cacheKey },
        retrieve: { networkSession.producer(for: URLRequest(url: $0)) }
    ).deduplicated

    /// A session to scale images to the correct size for display.
    fileprivate static let scaledImageSession: Session<ImageScaleRequest, LoadedImage, NSError> = PINCacheSession(
        cache: cache,
        makeKey: { "\($0.url.cacheKey)|\($0.scale)|\($0.size)" },
        retrieve: { request in
            imageSession.producer(for: request.url).attemptMap({ image in
                image.scaleTo(size: request.size, scale: request.scale).map({ scaled in
                    LoadedImage(image: scaled, originalSize: image.size)
                })
            })
        }
    ).deduplicated
}

// MARK: - Loading Images
extension UIImage
{
    /// Loads an image via cache or network.
    ///
    /// - parameter URL: The image URL to load.
    ///
    /// - returns: A signal producer for the image.
    static func load(url: URL) -> SignalProducer<LoadedImage, NSError>
    {
        return imageSession.producer(for: url).map({ image in
            LoadedImage(image: image, originalSize: image.size)
        })
    }

    /// Loads a scaled image via cache or network.
    ///
    /// - parameter URL:   The image URL to load.
    /// - parameter scale: The pixel scale of the desired image.
    /// - parameter size:  The size of the desired image.
    ///
    /// - returns: A signal producer for the scaled image.
    static func load(url: URL, scale: CGFloat, fitTo size: CGSize) -> SignalProducer<LoadedImage, NSError>
    {
        return scaledImageSession.producer(for: ImageScaleRequest(url: url, scale: scale, size: size))
    }
}

// MARK: - Scaling Images
extension UIImage
{
    /// Scales the image to fit in a specific size.
    ///
    /// - parameter size:  The size to fit the image within.
    /// - parameter scale: The pixel scale of the resulting image.
    ///
    /// - returns: A scaled image of maximum dimensions `size`.
    fileprivate func scaleTo(size: CGSize, scale: CGFloat) -> Result<UIImage, NSError>
    {
        let fitSize = self.size.fit(in: size).rounded()

        UIGraphicsBeginImageContextWithOptions(fitSize, hasAlpha, scale)
        draw(in: CGRect(origin: .zero, size: fitSize))

        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return Result(scaled, failWith: ImageLoadingError.failedToScale as NSError)
    }

    private var hasAlpha: Bool
    {
        return cgImage.map({ image in
            let alpha = image.alphaInfo
            return alpha == .premultipliedLast || alpha == .premultipliedFirst || alpha == .last || alpha == .first
        }) ?? true
    }
}

// MARK: - Image Loading Errors
enum ImageLoadingError: Int, Error
{
    case invalidData
    case failedToScale
}

extension ImageLoadingError: CustomNSError
{
    static let errorDomain = "com.natestedman.PrettyOkay.ImageLoadingError"
}

// MARK: - URL Cache Keys
extension URL
{
    fileprivate var cacheKey: String { return absoluteString }
}
