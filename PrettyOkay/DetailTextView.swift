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

import ReactiveCocoa
import ReactiveSwift
import UIKit
import enum Result.NoError

final class DetailTextView: UIView
{
    // MARK: - Data

    /// The content displayed by the view.
    let data = MutableProperty((title: String?, details: NSAttributedString?, buttonEnabled: Bool)?.none)

    // MARK: - Labels

    /// The label displaying the view's title.
    private let titleLabel = UILabel(frame: .zero)

    /// The button displaying the view's details.
    fileprivate let detailsButton = UIButton(frame: .zero)

    /// The number of lines displayed by the title label.
    var numberOfTitleLines: Int
    {
        get { return titleLabel.numberOfLines }
        set { titleLabel.numberOfLines = newValue }
    }

    // MARK: - Initialization
    private func setup()
    {
        titleLabel.font = UIFont.standard(weight: UIFontWeightMedium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .highlightedControlColor

        detailsButton.contentEdgeInsets = .zero
        detailsButton.titleEdgeInsets = .zero

        [titleLabel, detailsButton].forEach(addSubview)

        data.producer.startWithValues({ [weak self] data in
            self?.titleLabel.text = data?.title

            if let details = data?.details
            {
                func detailsAttributedString(_ color: UIColor) -> NSAttributedString
                {
                    let mutable = details.mutableCopy() as! NSMutableAttributedString

                    mutable.addAttribute(
                        NSForegroundColorAttributeName,
                        value: color,
                        range: NSMakeRange(0, mutable.length)
                    )

                    return mutable
                }

                self?.detailsButton.setAttributedTitle(detailsAttributedString(.normalControlColor), for: .normal)
                self?.detailsButton.setAttributedTitle(
                    detailsAttributedString(.highlightedControlColor),
                    for: .highlighted
                )
            }

            self?.detailsButton.isUserInteractionEnabled = data?.buttonEnabled ?? false
            self?.setNeedsLayout()
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

    // MARK: - Sizing
    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        let titleHeight = titleLabel.sizeThatFits(size).height

        let detailsHeight = detailsButton.attributedTitle(for: .normal)?.string.characters.count ?? 0 > 0
            ? (detailsButton.titleLabel?.sizeThatFits(size).height ?? 0)
            : 0

        return CGSize(
            width: size.width,
            height: titleHeight + detailsHeight + Layout.sidePadding * (detailsHeight > 0 ? 2 : 1)
        )
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        let size = bounds.size

        let titleHeight = titleLabel.sizeThatFits(CGSize(width: size.width, height: .greatestFiniteMagnitude)).height
        titleLabel.frame = CGRect(x: 0, y: 0, width: size.width, height: titleHeight)
        detailsButton.frame = CGRect(x: 0, y: titleHeight, width: size.width, height: size.height - titleHeight)
    }
}

extension Reactive where Base: DetailTextView
{
    var buttonTapped: Signal<(), NoError>
    {
        return base.detailsButton.reactive.controlEvents(.touchUpInside).map({ _ in () })
    }
}
