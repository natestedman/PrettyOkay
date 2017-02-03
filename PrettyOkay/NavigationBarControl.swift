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

final class NavigationBarControl: UIControl
{
    // MARK: - Initialization
    convenience init(item: BarItem)
    {
        self.init(frame: .zero)
        update(item: item, animatedWithDuration: nil)
    }

    // MARK: - Labels
    private var label: UILabel?
    private var oldLabels = [UILabel:CGSize]()

    private var labelColor: UIColor
    {
        return isHighlighted || (item?.highlighted ?? false)
            ? UIColor.highlightedControlColor
            : UIColor.normalControlColor
    }

    // MARK: - Highlighting
    override var isHighlighted: Bool { didSet { label?.textColor = labelColor } }

    // MARK: - Items
    func update(item: BarItem, animatedWithDuration duration: TimeInterval?)
    {
        let oldItem = self.item
        self.item = item

        if let label = self.label, oldItem?.text == item.text
        {
            label.textColor = labelColor
        }
        else
        {
            // store old label for fade out and removal
            let old = label

            // add a new label
            let new = UILabel()
            new.textColor = labelColor
            new.font = UIFont.standard()
            new.text = item.text
            addSubview(new)

            // layout to center the new view correctly
            label = new
            UIView.performWithoutAnimation(layoutSubviews)

            if let animationDuration = duration
            {
                old.apply({ oldLabels[$0] = $0.bounds.size })
                new.alpha = 0

                UIView.animate(withDuration: animationDuration, animations: {
                    UIView.setAnimationCurve(.linear)
                    new.alpha = 1
                    old?.alpha = 0
                }, completion: { _ in
                    old?.removeFromSuperview()
                    old.apply({ self.oldLabels.removeValue(forKey: $0) })
                })
            }
            else
            {
                old?.removeFromSuperview()
            }
        }
    }

    /// The item displayed by this button.
    private(set) var item: BarItem?

    /// The amount of points that the labels should be inset from the left and right of the view.
    var sideInset: CGFloat = Layout.sidePadding { didSet { setNeedsLayout() } }

    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        return label?.sizeThatFits(size) ?? .zero
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let bounds = self.bounds

        if let label = self.label
        {
            let height = label.sizeThatFits(.greatestFiniteMagnitude).height

            label.frame = CGRect(
                x: sideInset,
                y: round(bounds.size.height / 2 - height / 2),
                width: bounds.size.width - sideInset * 2,
                height: height
            )
        }

        oldLabels.forEach({ label, size in
            label.frame = size.centered(in: bounds)
        })
    }
}
