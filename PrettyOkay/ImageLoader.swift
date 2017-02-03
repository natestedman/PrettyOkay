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

import ReactiveSwift
import Result

final class ImageLoader
{
    // MARK: - Initialization
    init()
    {
        let size = MutableProperty(CGSize.zero)

        let displayProducer: SignalProducer<Display, NoError> = imageURL.producer
            .skipRepeats(==)
            .flatMapOptional(.latest, transform: { url -> SignalProducer<Display, NoError> in
                // only use the initial nil to clear the view once, regardless of size changes
                SignalProducer(value: .loading).concat(
                    size.producer.flatMap(.latest, transform: { size -> SignalProducer<LoadedImage, NSError> in
                            size == .zero
                                ? UIImage.load(url: url)
                                : UIImage.load(url: url, scale: UIScreen.main.scale, fitTo: size)
                        })
                        .results()
                        .map({ (result: Result<LoadedImage, NSError>) -> Display in
                            result.analysis(
                                ifSuccess: Display.image,
                                ifFailure: Display.failure
                            )
                        })
                )
            })
            .map({ flatten($0) ?? .empty })

        display = Property(
            initial: .empty,
            then: displayProducer.combineLatest(with: fallbackImage.producer).map({ display, fallback -> Display in
                if let fallbackImage = fallback, display.allowFallback
                {
                    return .image(fallbackImage)
                }
                else
                {
                    return display
                }
            })
        )

        self.size = size
    }

    // MARK: - Image Display
    enum Display: Equatable
    {
        case empty
        case loading
        case image(LoadedImage)
        case failure(NSError)
    }

    /// The result of the current image load operation.
    let display: Property<Display>

    // MARK: - Image Loading

    /// The image URL for the view to load.
    let imageURL = MutableProperty<URL?>(nil)

    /// An image to display in the image view, if the loaded image is not available.
    let fallbackImage = MutableProperty<LoadedImage?>(nil)

    let size: MutableProperty<CGSize>
}

extension ImageLoader.Display
{
    var image: LoadedImage?
    {
        switch self
        {
        case let .image(image):
            return image
        default:
            return nil
        }
    }

    fileprivate var allowFallback: Bool
    {
        switch self
        {
        case .empty, .loading, .failure:
            return true
        case .image:
            return false
        }
    }

    var isFailure: Bool
    {
        switch self
        {
        case .empty, .loading, .image:
            return false
        case .failure:
            return true
        }
    }
}

func ==(lhs: ImageLoader.Display, rhs: ImageLoader.Display) -> Bool
{
    switch (lhs, rhs)
    {
    case (.empty, .empty):
        return true
    case (.loading, .loading):
        return true
    case let (.image(lhsValue), .image(rhsValue)):
        return lhsValue == rhsValue
    case let (.failure(lhsError), .failure(rhsError)):
        return lhsError == rhsError
    default:
        return false
    }
}
