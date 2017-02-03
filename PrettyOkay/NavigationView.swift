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

final class NavigationView: UIView
{
    // MARK: - Items
    func update(items: BarItems, animatedWithDuration duration: TimeInterval?)
    {
        navigationBar.update(items: items, animatedWithDuration: duration)
    }

    /// A callback sent when an item is tapped.
    var itemTapped: ((BarItem.Action) -> ())?

    // MARK: - Navigation Bar Subviews

    /// The navigation bar.
    private let navigationBar = NavigationBarView()

    // MARK: - Separator Subviews

    /// The navigation bar separator.
    private let navigationSeparator = UIView()

    // MARK: - Content Subview

    /// The content view displayed by the view.
    var contentView: UIView?
    {
        didSet
        {
            oldValue?.removeFromSuperview()

            if let view = contentView
            {
                insertSubview(view, at: 0)
            }
        }
    }

    // MARK: - Modal Subview

    /// The modal view displayed by the view.
    ///
    /// Setting this property will not actually show or hide the view - use `showModal` to do that.
    var modalView: UIView?
    {
        didSet
        {
            oldValue?.removeFromSuperview()

            if let view = modalView
            {
                modalContainer.addSubview(view)
                view.autoPinEdgesToSuperviewEdges()
            }
        }
    }

    /// Whether or not the modal view should be displayed (whether or not one is actually set).
    var showModal: Bool = false
    {
        didSet { setNeedsLayout() }
    }

    /// The modal overlay, which contains and masks `modalContainer`.
    private let modalOverlay = UIView()

    /// A container view for `modalView`.
    private let modalContainer = UIView()

    // MARK: - Initialization
    private func setup()
    {
        // add bars and separators
        navigationBar.backgroundColor = .white
        addSubview(navigationBar)

        navigationSeparator.backgroundColor = UIColor.separatorColor
        addSubview(navigationSeparator)

        // modal setup
        modalOverlay.backgroundColor = .white
        modalOverlay.clipsToBounds = true
        addSubview(modalOverlay)
        modalOverlay.addSubview(modalContainer)

        // callback setup
        navigationBar.itemTapped = { [weak self] in self?.itemTapped?($0) }
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
    override func layoutSubviews()
    {
        super.layoutSubviews()

        // metrics for layout
        let size = bounds.size

        let inset = Layout.navigationBarHeight + Layout.separatorThickness

        // content view
        contentView?.frame = CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height - inset
        )

        // modal
        modalOverlay.frame = CGRect(
            x: 0,
            y: !showModal ? size.height - inset + Layout.separatorThickness : 0,
            width: size.width,
            height: showModal ? size.height - inset + Layout.separatorThickness : 0
        )

        modalContainer.frame = CGRect(
            x: 0,
            y: !showModal ? -size.height + inset : 0,
            width: size.width,
            height: size.height - inset
        )

        // navigation
        navigationSeparator.frame = CGRect(
            x: 0,
            y: showModal ? -Layout.separatorThickness : size.height - inset,
            width: size.width,
            height: Layout.separatorThickness
        )

        navigationBar.frame = CGRect(
            x: 0,
            y: size.height - inset + Layout.separatorThickness,
            width: size.width,
            height: Layout.navigationBarHeight
        )
    }
}

