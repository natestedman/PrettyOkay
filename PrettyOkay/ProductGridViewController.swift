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

import ArrayLoader
import ArrayLoaderInterface
import LayoutModules
import PrettyOkayKit
import ReactiveSwift
import Result
import UIKit

/// A base class for view controllers that display a grid of products.
class ProductGridViewController: BaseViewController
{
    // MARK: - Array Loader

    /// An array loader of products to display. Defaults to an empty array loader.
    let arrayLoader = MutableProperty(StaticArrayLoader<Product>.empty.promoteErrors(NSError.self))

    // MARK: - Collection View Controller

    /// A custom header view to insert. Subclasses should override this property.
    var customHeaderView: UIView? { return nil }

    typealias CollectionViewController = ArrayLoaderCollectionViewController
        <ProductCell, ErrorCell, ActivityCell, UICollectionViewCell>

    private lazy var collectionViewController: CollectionViewController =
        { [weak self] () -> CollectionViewController in
            let valuesLayoutModule = LayoutModule.grid(
                minimumMinorDimension: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 120,
                padding: Size(major: Layout.sidePadding, minor: Layout.sidePadding)
            ).inset(
                minMajor: Layout.sidePadding,
                maxMajor: Layout.sidePadding,
                minMinor: Layout.sidePadding,
                maxMinor: Layout.sidePadding
            )

            return CollectionViewController(
                activityItemSize: CGSize(width: 100, height: 100),
                errorItemSize: CGSize(width: 150, height: 100),
                completedItemSize: .zero,
                customHeaderView: self?.customHeaderView,
                valuesLayoutModule: valuesLayoutModule
            )
        }()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add collection view
        collectionViewController.collectionView.alwaysBounceVertical = true
        view.addSubview(collectionViewController.collectionView)

        collectionViewController.collectionView.autoPinEdge(toSuperviewEdge: .left)
        collectionViewController.collectionView.autoPinEdge(toSuperviewEdge: .right)
        collectionViewController.collectionView.autoPinEdge(toSuperviewEdge: .bottom)
        pinCollectionViewToTop(collectionViewController.collectionView)
        collectionViewController.collectionView.backgroundColor = UIColor.white
    }

    /// Allows subclasses to insert additional subviews above the collection view. The default implementation simply
    /// pins the collection view to the top of the view controller's view. Overriding implementations should not call
    /// the superclass implementation.
    ///
    /// - parameter collectionView: The collection view.
    func pinCollectionViewToTop(_ collectionView: UIView)
    {
        collectionView.autoPinEdge(toSuperviewEdge: .top)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // bind collection view controller
        collectionViewController.arrayLoader <~ arrayLoader

        // collection view controller callbacks
        collectionViewController.didSelectValue = { [weak self] cell, value in
            guard let strong = self else { return }

            let product = ProductViewController()
            product.clients <~ strong.clients
            product.model.value = (product: value, fallbackImage: (cell as? ProductCell)?.currentImage)
            strong.navigationController?.pushViewController(product, animated: true)
        }

        collectionViewController.didScroll = { [weak self] in self?.didScroll(offset: $0) }

        // register wants
        arrayLoader.producer
            .flatMap(.latest, transform: { $0.events })
            .map({ $0.newElements })
            .skipNil()
            .startWithValues({ [weak self] products in
                guard let wants = self?.clients.value?.want else { return }
                products.forEach({ wants.initialize(identifier: $0.identifier, goodDeletePath: $0.goodDeletePath) })
            })
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        collectionViewController.collectionView.indexPathsForSelectedItems?.forEach({ indexPath in
            collectionViewController.collectionView.deselectItem(at: indexPath, animated: animated)
        })
    }

    /// Subclasses may override.
    func didScroll(offset: CGPoint) {}
}
