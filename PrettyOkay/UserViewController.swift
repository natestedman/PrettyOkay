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
import SafariServices
import UIKit
import enum Result.NoError
import func Tuplex.unwrap

/// Displays a user and his or her products.
final class UserViewController: ProductGridViewController
{
    // MARK: - Model

    /// The models for a `UserViewController`.
    enum Model
    {
        /// A user value is provided directly - for cases where the user has been loaded as part of a result.
        case user(user: PrettyOkayKit.User, fallbackAvatarImage: LoadedImage?)

        /// A username is provided - for the current user, for which there isn't a direct JSON endpoint. The user's
        /// goods can be used to provide the user value later.
        case username(String)
    }

    /// The model for this view controller.
    let model = MutableProperty<Model?>(nil)

    // MARK: - User View

    /// The user view displayed by this view controller as a header.
    fileprivate let userView = UserView.newAutoLayout()

    /// The header view is overridden to insert `userView`.
    override var customHeaderView: UIView? { return userView }

    // MARK: - Backing Data

    /// The filters currently applied to the user's products.
    fileprivate let filters = MutableProperty(Filters())

    /// The data that is actually used for display, derived from `model` and `goodsArrayLoader`.
    fileprivate let displayModel = MutableProperty<Model?>(nil)

    /// The array loader for the user's goods. This is mapped to a product array loader to use with `arrayLoader`.
    fileprivate let goodsArrayLoader = MutableProperty<AnyArrayLoader<Good, NSError>>(
        StaticArrayLoader.empty.promoteErrors(NSError.self)
    )

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // a producer for the current first loaded good - this allows us to provide the logged in user when necessary
        let firstGoodProducer = goodsArrayLoader.producer
            .flatMap(.latest, transform: { $0.state.producer })
            .map({ $0.elements.first?.owner })

        // when a user value is unavailable, use the user from the first loaded good
        displayModel <~ model.producer
            .combineLatest(with: firstGoodProducer)
            .map({ optionalModel, optionalFirst in
                unwrap(optionalModel, optionalFirst).flatMap({ model, first in
                    model.isUsername ? .user(user: first, fallbackAvatarImage: nil) : nil
                }) ?? optionalModel
            })

        // this producer will send a value whenever the current user's wants change, so that we can reload the array
        // loader if we are displaying the current user
        let wantsChangedProducer = want.producer
            .flatMapOptional(.latest, transform: { SignalProducer($0.changedSignal) })
            .delay(1, on: QueueScheduler(qos: .userInitiated, name: "Wants Changed"))

        // need to skip repeats, so that the array loader doesn't reload after `firstGoodProducer` sends a value
        let usernameProducer = displayModel.producer.map({ $0?.username }).skipRepeats(==)

        goodsArrayLoader <~ SignalProducer.combineLatest(api.producer, usernameProducer, filters.producer)
            .flatMap(.latest, transform: { optionalAPI, optionalUsername, filters -> SignalProducer<AnyArrayLoader<Good, NSError>, NoError> in
                guard let API = optionalAPI, let username = optionalUsername else {
                    return SignalProducer(value: StaticArrayLoader.empty.promoteErrors(NSError.self))
                }

                let loadStrategy = API.goodsLoadStrategy(username: username, filters: filters, limit: 40)
                let makeLoader = { AnyArrayLoader(StrategyArrayLoader(load: loadStrategy)) }

                return username == API.authentication?.username
                    ? SignalProducer(value: ()).concat(wantsChangedProducer).map({ _ in makeLoader() })
                    : SignalProducer(value: makeLoader())
            })

        // map the goods to a products array loader that the superclass can handle
        arrayLoader <~ goodsArrayLoader.producer.map({ loader in loader.mapElements({ $0.product }) })

        // set the view controller's title, which appears on back buttons
        displayModel.producer.observe(on: UIScheduler()).startWithValues({ [weak self] in self?.title = $0?.username })

        // set up the user view
        let currentUsernameProducer = api.producer.map({ $0?.authentication?.username })
        userView.model <~ displayModel.producer.combineLatest(with: currentUsernameProducer)
            .map({ $0?.userViewModel(currentUsername: $1) })
            .observe(on: UIScheduler())

        userView.reactive.detailsTapped.observeValues({ [weak self] user in
            if let URL = user.URL, URL.scheme == "http" || URL.scheme == "https"
            {
                self?.present(SFSafariViewController(url: URL), animated: true, completion: nil)
            }
        })

        // settings could use a custom interface eventuall
        userView.reactive.settingsTapped.observeValues({ [weak self] button in
            guard let strong = self else { return }

            let sheet = UIAlertController(
                title: UIDevice.current.userInterfaceIdiom == .pad ? nil : "Settings",
                message: nil,
                preferredStyle: .actionSheet
            )

            sheet.popoverPresentationController?.sourceView = button
            sheet.popoverPresentationController?.sourceRect = button.bounds

            sheet.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { [weak self] _ in
                self?.clients.value?.authenticate(nil)
            }))

            sheet.addAction(UIAlertAction(title: "About", style: .default, handler: { [weak self] _ in
                self?.navigationController?.pushViewController(AboutViewController(), animated: true)
            }))

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            strong.present(sheet, animated: true, completion: nil)
        })
    }

    // MARK: - Collection View Callbacks
    override func didScroll(offset: CGPoint)
    {
        userView.yContentOffset = offset.y
    }
}

extension UserViewController: BarActionsProvider
{
    var barActionsProducer: SignalProducer<[BarItem], NoError>
    {
        return filters.filtersBarActionsProducer
    }
}

extension UserViewController.Model
{
    fileprivate func userViewModel(currentUsername: String?) -> UserView.Model?
    {
        switch self
        {
        case let .user(user, fallbackAvatarImage):
            return (
                user: user,
                isCurrentUser: currentUsername == user.username,
                fallbackAvatarImage: fallbackAvatarImage
            )
        case .username:
            return nil
        }
    }

    fileprivate var username: String
    {
        switch self
        {
        case let .user(user, _):
            return user.username
        case let .username(username):
            return username
        }
    }

    fileprivate var isUsername: Bool
    {
        switch self
        {
        case .user:
            return false
        case .username:
            return true
        }
    }
}
