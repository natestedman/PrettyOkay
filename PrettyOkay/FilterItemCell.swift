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

final class FilterItemCell: UITableViewCell
{
    // MARK: - Text Content
    private let label = UILabel(frame: .zero)

    /// The item text displayed by the cell.
    var itemText: String?
    {
        get { return label.text }
        set
        {
            label.text = newValue
            setNeedsLayout()
        }
    }

    // MARK: - Initialization
    private func setup()
    {
        selectionStyle = .none

        updateSelectionAppearance()
        contentView.addSubview(label)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Selection
    override var isSelected: Bool { didSet { updateSelectionAppearance() } }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        if animated
        {
            UIView.transition(with: label, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.updateSelectionAppearance()
            }, completion: nil)
        }
        else
        {
            updateSelectionAppearance()
        }
    }

    private func updateSelectionAppearance()
    {
        label.font = .standard(weight: isSelected ? UIFontWeightMedium : UIFontWeightRegular)
        label.textColor = isSelected ? UIColor.highlightedControlColor : UIColor.normalControlColor
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        let size = contentView.bounds.size
        let labelSize = label.sizeThatFits(size)

        label.frame = CGRect(
            x: 0,
            y: round(size.height / 2 - labelSize.height / 2),
            width: size.width,
            height: labelSize.height
        )
    }
}
