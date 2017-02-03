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

import PureLayout
import UIKit

final class NavigationBarView: UIView
{
    // MARK: - Items
    private var items = BarItems(leading: [], trailing: [])

    /// A callback sent when an item is tapped.
    var itemTapped: ((BarItem.Action) -> ())?

    /// Updates the bar items displayed by this view.
    ///
    /// - parameter items:    The new bar items.
    /// - parameter duration: The duration of the animation, if any.
    func update(items: BarItems, animatedWithDuration duration: TimeInterval?)
    {
        let duration = 0.25

        // reverse trailing so that it appears in the expected order
        let trailing = Array(items.trailing.reversed())

        // grab current buttons
        let currentLeading = leadingButtons
        let currentTrailing = trailingButtons

        // insert additional buttons
        while leadingButtons.count < items.leading.count
        {
            leadingButtons.append(makeButton(for: items.leading[leadingButtons.count]))

            if leadingButtons.count > 1
            {
                leadingSeparators.append(makeSeparator())
            }
        }

        while trailingButtons.count < trailing.count
        {
            trailingButtons.append(makeButton(for: trailing[trailingButtons.count]))

            if trailingButtons.count > 1
            {
                trailingSeparators.append(makeSeparator())
            }
        }

        // remove extra buttons
        var leadingToRemove: [UIView] = []

        while leadingButtons.count > items.leading.count
        {
            leadingToRemove.append(leadingButtons.removeLast())

            if leadingSeparators.count > 0
            {
                leadingToRemove.append(leadingSeparators.removeLast())
            }
        }

        var trailingToRemove: [UIView] = []

        while trailingButtons.count > trailing.count
        {
            trailingToRemove.append(trailingButtons.removeLast())

            if trailingSeparators.count > 0
            {
                trailingToRemove.append(trailingSeparators.removeLast())
            }
        }

        // prep layout for animation
        UIView.performWithoutAnimation(layoutIfNeeded)

        // update existing buttons
        let pairs = [(items.leading, currentLeading), (trailing, currentTrailing)]

        pairs.forEach({ items, buttons in
            zip(items, buttons).forEach({ item, button in
                button.update(item: item, animatedWithDuration: duration)
            })
        })

        // keep track of the bounds of the views that will stay, so that we can translate the views that are leaving
        let startLeadingX = leadingButtons.last?.frame.maxX ?? 0

        setNeedsLayout()

        // remove old buttons and separators
        UIView.animate(withDuration: duration, animations: {
            // layout the main subviews
            self.layoutIfNeeded()

            // fade out leading views that have been removed
            let endLeadingX = self.leadingButtons.last?.frame.maxX ?? 0
            let leadingTransform = CGAffineTransform(translationX: endLeadingX - startLeadingX, y: 0)

            leadingToRemove.forEach({
                $0.alpha = 0
                $0.transform = leadingTransform
            })

            trailingToRemove.forEach({ $0.alpha = 0 })
        }, completion: { _ in
            leadingToRemove.forEach({ $0.removeFromSuperview() })
            trailingToRemove.forEach({ $0.removeFromSuperview() })
        })
    }

    // MARK: - Item Views
    private var leadingButtons: [NavigationBarControl] = []
    private var leadingSeparators: [UIView] = []
    private var trailingButtons: [NavigationBarControl] = []
    private var trailingSeparators: [UIView] = []

    /// Creates and adds a button.
    ///
    /// - parameter item: The item for the button.
    private func makeButton(for item: BarItem) -> NavigationBarControl
    {
        let button = NavigationBarControl(item: item)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        addSubview(button)
        return button
    }

    /// Creates and adds a separator view.
    private func makeSeparator() -> UIView
    {
        let label = UILabel()
        label.font = UIFont.standard()
        label.textColor = UIColor(white: 0.75, alpha: 1)
        label.text = "/"
        addSubview(label)
        return label
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        // layout for navigation on the left
        var offset = Layout.sidePadding
        let size = bounds.size

        /// A function for laying out two sequences of action controls and separators.
        ///
        /// - parameter start:      The starting coordinate.
        /// - parameter forward:    Whether the layout should progress forward or backward in the coordinate system.
        /// - parameter views:      The action views to position.
        /// - parameter separators: The separators to position.
        func layout(start: CGFloat, forward: Bool, views: [UIView], separators: [UIView], max: CGFloat?)
        {
            var offset = start

            /// A function for laying out an individual view.
            ///
            /// - parameter view:  The view to lay out.
            /// - parameter extra: The amount of extra padding to place on either side of the view.
            /// - parameter fill:  Whether or not the view should take up all available space in the non-layout
            ///                    direction.
            func layout(view: UIView, extra: CGFloat, fill: Bool)
            {
                var viewSize = view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                viewSize.width += extra * 2

                if !forward { offset -= viewSize.width }

                let x = max.map({ min($0, offset) }) ?? offset
                let maxWidth = max.map({ $0 - offset })

                view.frame = CGRect(
                    x: x,
                    y: fill ? 0 : round(size.height / 2 - viewSize.height / 2),
                    width: maxWidth.map({ min($0, viewSize.width) }) ?? viewSize.width,
                    height: fill ? size.height : viewSize.height
                )

                if forward { offset += viewSize.width }
            }

            zip(views, separators).forEach({ view, separator in
                layout(view: view, extra: Layout.sidePadding, fill: true)
                layout(view: separator, extra: 0, fill: false)
            })

            views.suffix(views.count - separators.count).forEach({ view in
                layout(view: view, extra: Layout.sidePadding, fill: true)
            })
        }

        layout(start: size.width, forward: false, views: trailingButtons, separators: trailingSeparators, max: nil)

        layout(
            start: 0,
            forward: true,
            views: leadingButtons,
            separators: leadingSeparators,
            max: (trailingButtons.last?.frame.minX).map({ $0 - Layout.sidePadding })
        )
    }

    // MARK: - Actions
    @objc private func buttonAction(sender: NavigationBarControl)
    {
        if let item = sender.item
        {
            itemTapped?(item.action)
        }
    }
}
