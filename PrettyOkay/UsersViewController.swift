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
import PureLayout
import ReactiveSwift
import UIKit
import enum Result.NoError

/// Displays a list of Very Goods users.
final class UsersViewController: BaseViewController
{
    // MARK: - Array Loader
    let arrayLoader = MutableProperty(AnyArrayLoader(StaticArrayLoader<User>.empty
        .promoteErrors(NSError.self))
    )

    /// The order in which users are sorted. This property is persistent.
    fileprivate let order: MutableProperty<Order> = MutableProperty(
        userDefaults: UserDefaults.standard,
        key: "UsersSortOrder",
        defaultValue: .alphabetical
    )

    // MARK: - Collection View Controller
    private let collectionViewController = ArrayLoaderCollectionViewController
        <UserCell, ErrorCell, ActivityCell, UICollectionViewCell>(
            activityItemSize: CGSize(width: 100, height: 100),
            errorItemSize: CGSize(width: 100, height: 100),
            completedItemSize: CGSize(width: 100, height: 0),
            valuesLayoutModule: LayoutModule.table(majorDimension: 80)
        )

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = "Users"

        // add collection view
        view.addSubview(collectionViewController.collectionView)
        collectionViewController.collectionView.autoPinEdgesToSuperviewEdges()
        collectionViewController.collectionView.backgroundColor = UIColor.white

        // bind collection view controller
        collectionViewController.arrayLoader <~ arrayLoader

        self.arrayLoader <~ api.producer.combineLatest(with: order.producer.skipRepeats())
            .map({ optionalAPI, order in
                guard let API = optionalAPI else { return StaticArrayLoader<User>.empty.promoteErrors(NSError.self) }
                
                let loadStategy = API.usersLoadStrategy(order: order, limit: 40)
                return AnyArrayLoader(StrategyArrayLoader(load: loadStategy))
            })

        // collection view controller callbacks
        collectionViewController.didSelectValue = { [weak self] cell, value in
            guard let strong = self else { return }

            let controller = UserViewController()
            controller.clients <~ strong.clients
            controller.model.value = .user(
                user: value,
                fallbackAvatarImage: (cell as? UserCell)?.currentImage
            )

            strong.navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        collectionViewController.collectionView.indexPathsForSelectedItems?.forEach({ indexPath in
            collectionViewController.collectionView.deselectItem(at: indexPath, animated: animated)
        })
    }
}

extension UsersViewController: BarActionsProvider
{
    var barActionsProducer: SignalProducer<[BarItem], NoError>
    {
        return order.producer.map({ order -> BarItem in
            switch order
            {
            case .alphabetical:
                return BarItem(
                    text: UIScreen.main.bounds.size.width > 321 ? "Alphabetical" : "Abc",
                    highlighted: false,
                    action: .execute({ [weak self] in self?.order.value = .newest })
                )
            case .newest:
                return BarItem(
                    text: "Newest",
                    highlighted: false,
                    action: .execute({ [weak self] in self?.order.value = .alphabetical })
                )
            }
        }).flatMap(.latest, transform: { SignalProducer(value: [$0]) })
    }
}
