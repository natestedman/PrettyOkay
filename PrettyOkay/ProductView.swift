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

import PrettyOkayKit
import ReactiveSwift
import UIKit

final class ProductView: UIView
{
    // MARK: - Model

    /// The display data type for a product view.
    typealias Model = (product: Product, fallbackImage: LoadedImage?)

    /// The product displayed by the view.
    let model = MutableProperty(Model?.none)

    // MARK: - Subviews
    private let headerView = HeaderImageView(frame: .zero)
    private let detailsView = DetailTextView(frame: .zero)
    private let separator = UIView(frame: .zero)

    // MARK: - Initialization
    private func setup()
    {
        detailsView.numberOfTitleLines = 3

        separator.backgroundColor = .separatorColor

        [headerView, detailsView, separator].forEach(addSubview)

        model.producer.startWithValues({ [weak self] data in
            self?.headerView.loader.fallbackImage.value = data?.fallbackImage
            self?.headerView.loader.imageURL.value = data?.product.imageURL
            self?.detailsView.data.value = (data?.product).map({ product in
                (title: product.title, details: product.detailsAttributedString, buttonEnabled: false)
            })
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
    }

    // MARK: - Layout
    static let imageHeight: CGFloat = 340

    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        return CGSize(
            width: size.width,
            height: ProductView.imageHeight + Layout.sidePadding + detailsView.sizeThatFits(size).height
        )
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let size = bounds.size

        let detailsFittingSize = CGSize(width: size.width - Layout.sidePadding * 2, height: CGFloat.greatestFiniteMagnitude)
        let detailsHeight = detailsView.sizeThatFits(detailsFittingSize).height

        detailsView.frame = CGRect(
            x: Layout.sidePadding,
            y: size.height - detailsHeight,
            width: size.width - Layout.sidePadding * 2,
            height: detailsHeight
        )

        let headerHeight = size.height - detailsHeight - Layout.sidePadding
        headerView.bounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: headerHeight)
        headerView.center = CGPoint(x: bounds.size.width / 2, y: headerHeight / 2)

        let separatorHeight = Layout.separatorThickness

        separator.frame = CGRect(
            x: Layout.sidePadding,
            y: bounds.size.height - separatorHeight,
            width: bounds.size.width - Layout.sidePadding * 2,
            height: separatorHeight
        )
    }

    // MARK: - Scroll Effect
    var yContentOffset: CGFloat = 0
    {
        didSet
        {
            if yContentOffset >= 0
            {
                headerView.transform = .identity
            }
            else
            {
                let scale = (ProductView.imageHeight - yContentOffset) / ProductView.imageHeight

                headerView.transform = CGAffineTransform(translationX: 0, y: yContentOffset / 2).scaledBy(
                    x: scale, y: scale
                )
            }
        }
    }
}

extension Product
{
    fileprivate var detailsAttributedString: NSAttributedString
    {
        return [
            NSAttributedString(string: formattedPrice, attributes: [
                NSFontAttributeName: UIFont.standard(weight: UIFontWeightThin)
            ]),
            displayDomain.map({
                NSAttributedString(string: $0, attributes: [NSFontAttributeName: UIFont.standard()])
            })
        ].flatMap({ $0 }).separatedDetailsAttributedString
    }
}

extension Collection where
    Index: Comparable,
    Iterator.Element == NSAttributedString,
    SubSequence.Iterator.Element == NSAttributedString
{
    var separatedDetailsAttributedString: NSAttributedString
    {
        let separator = NSAttributedString(string: " / ", attributes: [
            NSFontAttributeName: UIFont.standard(weight: UIFontWeightThin)
        ])

        let result = NSMutableAttributedString()

        for detail in self.dropLast()
        {
            result.append(detail)
            result.append(separator)
        }

        if let last = self.first
        {
            result.append(last)
        }

        return result
    }
}
