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
import enum Result.NoError

final class FiltersViewController: UIViewController
{
    // MARK: - Category View Controllers
    private let price = FilterComponentViewController<Price>()
    private let category = FilterComponentViewController<PrettyOkayKit.Category>()
    private let gender = FilterComponentViewController<Gender>()

    // MARK: - View Loading
    override func loadView()
    {
        let view = FiltersView()
        view.backgroundColor = .white
        self.view = view

        let children = [price, category, gender]

        children.forEach(addChildViewController)
        view.views = (left: price.view, center: category.view, right: gender.view)
        children.forEach({ $0.didMove(toParentViewController: self) })
    }

    // MARK: - Filters

    /// A producer for the currently selected filters.
    var filtersProducer: SignalProducer<Filters, NoError>
    {
        return SignalProducer.combineLatest(
            price.selectedItems.producer,
            gender.selectedItems.producer,
            category.selectedItems.producer
        ).map(Filters.init)
    }

    func select(filters: Filters, animated: Bool)
    {
        price.animateSelectionChanges = animated
        gender.animateSelectionChanges = animated
        category.animateSelectionChanges = animated

        price.selectedItems.value = filters.price
        gender.selectedItems.value = filters.gender
        category.selectedItems.value = filters.category

        price.animateSelectionChanges = false
        gender.animateSelectionChanges = false
        category.animateSelectionChanges = false
    }
}

extension FiltersViewController: BarActionsProvider
{
    var barActionsProducer: SignalProducer<[BarItem], NoError>
    {
        let items = [
            BarItem(
                text: "All",
                highlighted: false,
                action: .execute({ [weak self] in self?.select(filters: Filters.all, animated: true) })
            ),
            BarItem(
                text: "None",
                highlighted: false,
                action: .execute({ [weak self] in self?.select(filters: Filters(), animated: true) })
            )
        ]

        return SignalProducer(value: items)
    }
}

private final class FiltersView: UIView
{
    var views: (left: UIView, center: UIView, right: UIView)?
    {
        didSet
        {
            oldValue?.left.removeFromSuperview()
            oldValue?.center.removeFromSuperview()
            oldValue?.right.removeFromSuperview()

            if let (left, center, right) = views
            {
                addSubview(left)
                addSubview(center)
                addSubview(right)
            }
        }
    }

    fileprivate override func layoutSubviews()
    {
        super.layoutSubviews()

        if let (left, center, right) = views
        {
            let boundsSize = bounds.size
            let viewSize = CGSize(width: round((boundsSize.width - Layout.sidePadding * 4) / 3), height: boundsSize.height)

            left.frame = CGRect(
                origin: CGPoint(x: Layout.sidePadding, y: 0),
                size: viewSize
            )

            center.frame = CGRect(
                origin: CGPoint(x: round(boundsSize.width / 2 - viewSize.width / 2), y: 0),
                size: viewSize
            )

            right.frame = CGRect(
                origin: CGPoint(x: boundsSize.width - viewSize.width - Layout.sidePadding, y: 0),
                size: viewSize
            )
        }
    }
}
