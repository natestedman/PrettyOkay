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
import PrettyOkayKit
import ReactiveSwift
import Result
import SafariServices
import UIKit
import func Tuplex.unwrap

/// Displays a single product and its relations.
final class ProductViewController: ProductGridViewController
{
    // MARK: - Product

    /// The product displayed by this view controller.
    let model = MutableProperty(Optional<ProductView.Model>.none)

    /// The result of attempting to load the product's relations.
    private let productRelationsResult = MutableProperty(Result<ProductRelations, NSError>?.none)

    // MARK: - Product View

    /// The product view displayed in the header of the view controller.
    private let productView = ProductView.newAutoLayout()

    /// Override to add the product view to the interface.
    override var customHeaderView: UIView?
    {
        return productView
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // display current product in the product view
        productView.model <~ model
        model.producer.startWithValues({ [weak self] in self?.title = $0?.product.title })

        // load product relations for each product, display the result as a static array loader
        typealias ResultProducer = SignalProducer<Result<ProductRelations, NSError>?, NoError>
 
        productRelationsResult <~ model.producer.map({ $0?.product.identifier })
            .combineLatest(with: api.producer)
            .map(unwrap)
            .flatMapOptional(.latest, transform: { identifier, API -> ResultProducer in
                SignalProducer(value: nil).concat(
                    API.productRelationsProducer(identifier: identifier)
                        .map({ Result.success($0) })
                        .flatMapError({ ResultProducer(value: Result.failure($0)) })
                )
            })
            .map({ $0 ?? nil })
 
        arrayLoader <~ productRelationsResult.producer.map({ optionalResult in
            guard let result = optionalResult else { return StaticArrayLoader.empty.promoteErrors(NSError.self) }

            return result.analysis(
                ifSuccess: { StaticArrayLoader(elements: $0.relatedProducts).promoteErrors(NSError.self) },
                ifFailure: { _ in StaticArrayLoader.empty.promoteErrors(NSError.self) }
            )
        })
    }

    // MARK: - Collection View Callbacks
    override func didScroll(offset: CGPoint)
    {
        productView.yContentOffset = offset.y
    }
}

extension ProductViewController
{
    // MARK: - Actions

    /// Presents a view controller for purchasing the product.
    ///
    /// - parameter product: The product to purchase.
    fileprivate func buy(product: Product)
    {
        if let URL = product.sourceURL
        {
            present(SFSafariViewController(url: URL), animated: true, completion: nil)
        }
        else
        {
            let alert = UIAlertController(
                title: "No URL",
                message: "The product “\(product.title)” does not have a source URL.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

            present(alert, animated: true, completion: nil)
        }
    }

    /// Toggles the want state of the product.
    ///
    /// - parameter product: The product.
    /// - parameter current: The current want state.
    fileprivate func toggleWant(product: Product, current: Bool)
    {
        clients.value?.want?.modify(identifier: product.identifier, want: !current)
    }
}

extension ProductViewController: BarActionsProvider
{
    var barActionsProducer: SignalProducer<[BarItem], NoError>
    {
        return model.producer.map({ $0?.product })
            .combineLatest(with: want.producer)
            .map(unwrap)
            .flatMapOptional(.latest, transform: { product, wants in
                wants.wantStateProducer(identifier: product.identifier).map({ ($0.isWanted, product) })
            })
            .mapOptional({ [weak self] wanted, product in
                return [
                    BarItem(
                        text: (wanted ?? false) ? "✓ Wanted" : "Want",
                        highlighted: false,
                        action: .execute({ [weak self] in
                            self?.toggleWant(product: product, current: wanted ?? false)
                        })
                    ),
                    BarItem(
                        text: "Buy",
                        highlighted: false,
                        action: .execute({ [weak self] in self?.buy(product: product) })
                    )
                ]
            })
            .map({ $0 ?? [] })
            .observe(on: UIScheduler())
    }
}
