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
import UIKit

final class ImageView: UIView
{
    // MARK: - Subviews

    // The image view, which displays the current image.
    private let imageView = UIImageView.newAutoLayout()

    /// The activity indicator, which is displayed while images are loading.
    private let activityIndicator = UIActivityIndicatorView.newAutoLayout()

    /// A view displayed when no image URL is set.
    private let emptyView = UILabel.newAutoLayout()

    /// The background color displayed when no image URL is set.
    private let emptyBackground = UIColor(white: 0.8, alpha: 1.0)

    /// The content mode to display the image with. Defaults to `.Center`.
    var imageContentMode = UIViewContentMode.center
    {
        didSet { imageView.contentMode = imageContentMode }
    }

    // MARK: - Initialization
    private func setup()
    {
        imageView.contentMode = .center
        addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        
        addSubview(emptyView)
        emptyView.font = UIFont.boldSystemFont(ofSize: 18)
        emptyView.textColor = UIColor.white
        emptyView.backgroundColor = emptyBackground
        emptyView.autoCenterInSuperview()
        
        addSubview(activityIndicator)
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.autoPinEdgesToSuperviewEdges()

        // show the empty view when there is no image sets
        let scheduler = UIScheduler()

        let isFailureProducer = loader.display.producer.map({ $0.isFailure })

        isFailureProducer.startWithValues({ [weak self] isFailure in
            self?.emptyView.text = isFailure ? ":(" : "?"
        })

        loader.imageURL.producer.map({ $0 != nil })
            .combineLatest(with: isFailureProducer)
            .observe(on: scheduler)
            .startWithValues({ [weak self] haveURL, isFailure in
                let showEmpty = !haveURL || isFailure
                self?.backgroundColor = showEmpty ? self?.emptyBackground : UIColor.clear
                self?.emptyView.isHidden = !showEmpty
            })

        // show the activity indicator when we have a URL, but it hasn't succeeded or failed yet
        activityIndicator.reactive.isAnimating <~ loader.display.producer
            .map({ $0 == .loading })
            .observe(on: scheduler)
        
        loader.display.producer
            .skipRepeats(==)
            .timed()
            .combinePrevious((.empty, 0))
            .skip(first: 1)
            .observe(on: scheduler)
            .startWithValues({ [weak self] previous, current in
                guard let strong = self else { return }

                if current.value.image != nil && previous.value.image == nil && current.time - previous.time > 0.1
                {
                    strong.imageView.alpha = 0
                    strong.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).rotated(
                        by: (0.5 - CGFloat(arc4random()) / CGFloat(UINT32_MAX)) / 5
                    )

                    UIView.animate(withDuration: 0.25, animations: {
                        UIView.setAnimationCurve(.linear)
                        strong.imageView.alpha = 1

                        UIView.setAnimationCurve(.easeOut)
                        strong.imageView.transform = .identity
                    })
                }
                else
                {
                    strong.imageView.alpha = 1
                    strong.imageView.transform = .identity
                }

                strong.imageView.image = current.value.image?.image
            })
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
        loader.imageURL.value = coder.decodeObject(of: NSURL.self, forKey: ImageView.imageURLKey) as? URL
    }

    override func encode(with coder: NSCoder)
    {
        super.encode(with: coder)
        coder.encode(loader.imageURL.value, forKey: ImageView.imageURLKey)
    }

    /// The key used to encode the image URL.
    private static let imageURLKey = "ImageView_imageURL"

    // MARK: - Loading

    /// The image loader for this view.
    let loader = ImageLoader()

    // MARK: - Dimensions
    override func layoutSubviews()
    {
        super.layoutSubviews()
        loader.size.value = bounds.size
    }
}

extension SignalProducerProtocol
{
    fileprivate typealias Timed = (value: Value, time: CFAbsoluteTime)

    fileprivate func timed() -> SignalProducer<Timed, Error>
    {
        return map({ (value: $0, time: CFAbsoluteTimeGetCurrent()) })
    }
}
