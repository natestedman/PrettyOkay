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

import ArrayLoaderInterface
import PrettyOkayKit
import UIKit

class UserCell: HighlightCell, ArrayLoaderValueDisplaying
{
    private let nameLabel = UILabel.newAutoLayout()
    private let detailsLabel = UILabel.newAutoLayout()
    private let imageView = ImageView.newAutoLayout()

    private func setup()
    {
        nameLabel.font = UIFont.standard(weight: UIFontWeightMedium)
        detailsLabel.font = UIFont.standard()
        detailsLabel.textColor = UIColor.gray

        let labelsContainer = UIView.newAutoLayout()
        labelsContainer.addSubview(nameLabel)
        labelsContainer.addSubview(detailsLabel)

        contentView.addSubview(labelsContainer)
        contentView.addSubview(imageView)

        imageView.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(top: Layout.sidePadding, left: Layout.sidePadding, bottom: Layout.sidePadding, right: Layout.sidePadding),
            excludingEdge: .trailing
        )

        imageView.autoMatch(.width, to: .height, of: imageView)

        labelsContainer.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: Layout.sidePadding)
        labelsContainer.autoPinEdge(toSuperviewEdge: .trailing, withInset: Layout.sidePadding)
        labelsContainer.autoAlignAxis(toSuperviewAxis: .horizontal)

        nameLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        detailsLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        detailsLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 2)

        // add separator to the bottom of the cell
        let separator = UIView.newAutoLayout()
        separator.backgroundColor = .separatorColor
        contentView.addSubview(separator)

        separator.autoSetDimension(.height, toSize: Layout.separatorThickness)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
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
    
    var value: User?
    {
        didSet
        {
            imageView.loader.imageURL.value = value?.avatarURLCentered126
            nameLabel.text = value?.name ?? value?.username

            detailsLabel.text = value?.goodsCount.goodsCountString

            setNeedsLayout()
        }
    }

    var currentImage: LoadedImage?
    {
        return imageView.loader.display.value.image
    }

    override var shouldAppearHighlighted: Bool
    {
        didSet
        {
            contentView.backgroundColor = shouldAppearHighlighted ? .separatorColor : .clear
        }
    }
}

extension ExpressibleByIntegerLiteral where Self: Equatable
{
    var goodsCountString: String
    {
        return "\(self) good\(pluralSuffix)"
    }

    private var pluralSuffix: String
    {
        return self == 1 ? "" : "s"
    }
}
