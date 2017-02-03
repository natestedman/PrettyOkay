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
import UIKit

final class HeaderImageView: UIView
{
    private let drawView = HeaderImageDrawView.newAutoLayout()

    // MARK: - Initialization
    private func setup()
    {
        addSubview(drawView)
        drawView.autoPinEdgesToSuperviewEdges()

        loader.display.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] in self?.drawView.image = $0.image })
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
    }

    // MARK: - Image Loading
    let loader = ImageLoader()

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()
        loader.size.value = bounds.size
    }
}

private final class HeaderImageDrawView: UIView
{
    var image: LoadedImage? { didSet { setNeedsDisplay() } }

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        let bounds = self.bounds

        if let loaded = image
        {
            var rect = loaded.originalSize.fit(in: bounds)

            // move to the top left corner
            while rect.maxX > 0
            {
                rect.origin.x -= rect.size.width
            }

            while rect.maxY > 0
            {
                rect.origin.y -= rect.size.height
            }

            // draw a grid of images
            let yOrigin = rect.origin.y

            while rect.minX < bounds.size.width
            {
                rect.origin.y = yOrigin

                while rect.minY < bounds.size.height
                {
                    loaded.image.draw(in: rect)
                    rect.origin.y += rect.size.height
                }

                rect.origin.x += rect.size.width
            }
        }
        else
        {
            UIColor.gray.set()
            UIRectFill(bounds)
        }
    }
}
