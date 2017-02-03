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
import enum Result.NoError

/// An item in a `NavigationBarView`.
struct BarItem
{
    // MARK: - Content

    /// The text that should be displayed for this bar item.
    let text: String

    // MARK: - Appearance

    /// If `true`, the item will appear highlighted.
    let highlighted: Bool

    // MARK: - Action

    /// The actions that can be performed when an item is tapped.
    enum Action
    {
        /// A function should be executed.
        case execute(() -> ())

        /// A view controller should be presented from the navigation bar.
        case presentFromBar(() -> BarPresentation?)

        /// A view controller should be popped from the navigation stack.
        case popNavigation

        /// A different root tab should be shown.
        case rootNavigation(RootNavigationItem)
    }

    /// The action to perform when this item is tapped.
    let action: Action
}

/// The value produced by a `presentFromBar` `BarItem`. Represents a view controller to present.
struct BarPresentation
{
    /// The view controller to display.
    let viewController: UIViewController

    /// A function to execute when the presentation ends.
    let completion: () -> ()
}

// MARK: - Items
struct BarItems
{
    /// Items that should appear on the leading side of the view.
    let leading: [BarItem]

    /// Items that should appear on the trailing side of the view.
    let trailing: [BarItem]
}

// MARK: - Actions Provider

/// A protocol for types that provide a number of action bar items.
protocol BarActionsProvider
{
    /// A producer for the action bar items provided by the receiver.
    var barActionsProducer: SignalProducer<[BarItem], NoError> { get }
}
