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
import PureLayout
import ReactiveSwift
import Result
import UIKit

final class NavigationBarViewController: BaseViewController
{
    // MARK: - State
    private let authentication = MutableProperty<Authentication?>(
        userDefaults: UserDefaults.standard,
        key: "PrettyOkay-Authentication"
    )

    // MARK: - Initialization
    init()
    {
        navigation = UINavigationController()
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder: NSCoder)
    {
        navigation = (coder.decodeObject(forKey: "child") as? UINavigationController) ?? UINavigationController()
        super.init(coder: coder)
        selectedRoot.value = RootNavigationItem(rawValue: coder.decodeInteger(forKey: "selectedRoot")) ?? .cover
        setup()
    }
    
    override func encode(with coder: NSCoder)
    {
        super.encode(with: coder)
        coder.encode(navigation, forKey: "navigation")
        coder.encode(selectedRoot.value.rawValue, forKey: "selectedRoot")
    }

    private func setup()
    {
        viewControllers.value = navigation.viewControllers
    }

    // MARK: - Subviews and Controllers
    fileprivate let navigation: UINavigationController
    fileprivate let navigationModalPresentation = MutableProperty(BarPresentation?.none)
    
    // MARK: - View Lifecycle
    fileprivate let navigationView = NavigationView(frame: .zero)

    override func loadView()
    {
        self.view = navigationView

        // add the navigation controller
        addChildViewController(navigation)
        navigationView.contentView = navigation.view
        navigation.didMove(toParentViewController: self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // bind base properties
        let authenticationProperty = self.authentication

        clients <~ authentication.producer.map({ authentication -> Clients in
            let api = APIClient(authentication: authentication)

            return Clients(
                api: api,
                want: authentication != nil ? WantClient(api: api) : nil,
                authenticate: { authenticationProperty.value = $0 }
            )
        })
        
        // configure child navigation controller
        navigation.delegate = self
        navigation.setNavigationBarHidden(true, animated: false)

        // adapt to changing root
        selectedRoot.producer
            .skipRepeats()
            .map({ $0.viewController })
            .startWithValues({ [weak self] viewController in
                guard let strong = self else { return }
                viewController.clients <~ strong.clients
                strong.navigation.viewControllers = [viewController]
                strong.viewControllers.value = strong.navigation.viewControllers
            })

        // bind navigation actions from current view controller
        SignalProducer.combineLatest(viewControllers.producer, navigationModalPresentation.producer, selectedRoot.producer)
            .flatMap(.latest, transform: { viewControllers, optionalModal, root -> SignalProducer<BarItems, NoError> in
                if let modal = optionalModal
                {
                    let actionsProducer = (modal.viewController as? BarActionsProvider)?.barActionsProducer
                        ?? SignalProducer(value: [])

                    let navigation = [BarItem(
                        text: "Done",
                        highlighted: false,
                        action: .presentFromBar({ nil })
                    )]

                    return actionsProducer.map({ items in
                        BarItems(leading: items, trailing: navigation)
                    })
                }
                else
                {
                    let actionsProducer = (viewControllers.last as? BarActionsProvider)?.barActionsProducer
                        ?? SignalProducer(value: [])

                    let navigationProducer = viewControllers.count > 1
                        ? (viewControllers.dropLast().last?.reactive.title ?? SignalProducer(value: nil))
                            .map({ $0 ?? "Back" })
                            .map({ [BarItem(text: "← \($0)", highlighted: false, action: .popNavigation)] })
                        : SignalProducer(value: RootNavigationItem.all.map({ $0.barItem(currentRoot: root) }))

                    return navigationProducer.combineLatest(with: actionsProducer).map(BarItems.init)
                }
            })
            .startWithValues({ [weak navigationView] items in
                navigationView?.update(items: items, animatedWithDuration: 0.25)
            })

        // perform navigation actions
        navigationView.itemTapped = { [weak self] action in
            guard let strong = self else { return }

            switch action
            {
            case .execute(let function):
                function()

            case .presentFromBar(let presentation):
                strong.navigationModalPresentation.value = presentation()

            case .popNavigation:
                strong.navigation.popViewController(animated: true)

            case .rootNavigation(let item):
                strong.selectedRoot.value = item
            }
        }

        // show modals in the navigation bar
        navigationModalPresentation.producer
            .combinePrevious(nil)
            .skip(first: 1)
            .startWithValues({ [weak self] optionalPrevious, optionalCurrent in
                guard let strong = self else { return }

                optionalPrevious?.completion()

                if let previous = optionalPrevious, let current = optionalCurrent
                {
                    previous.viewController.willMove(toParentViewController: nil)
                    strong.addChildViewController(current.viewController)

                    strong.navigationView.modalView = current.viewController.view

                    previous.viewController.removeFromParentViewController()
                    current.viewController.didMove(toParentViewController: strong)
                }
                else if let previous = optionalPrevious
                {
                    UIView.animate(withDuration: 0.5, animations: {
                        strong.navigationView.showModal = false
                        strong.navigationView.layoutIfNeeded()
                    }, completion: { _ in
                        previous.viewController.willMove(toParentViewController: nil)
                        strong.navigationView.modalView = nil
                        previous.viewController.removeFromParentViewController()
                    })
                }
                else if let current = optionalCurrent
                {
                    strong.addChildViewController(current.viewController)
                    strong.navigationView.modalView = current.viewController.view
                    current.viewController.didMove(toParentViewController: strong)

                    strong.navigationView.layoutIfNeeded()

                    UIView.animate(withDuration: 0.5, animations: {
                        strong.navigationView.showModal = true
                        strong.navigationView.layoutIfNeeded()
                    })
                }
            })
    }

    // MARK: - State

    /// The current view controller stack.
    fileprivate let viewControllers = MutableProperty<[UIViewController]>([])

    /// The current root view.
    fileprivate let selectedRoot = MutableProperty<RootNavigationItem>(
        userDefaults: UserDefaults.standard,
        key: "SelectedRootNavigationItem",
        defaultValue: .cover
    )

    // MARK: - Navigation Bar

    /// The navigation actions for the current view controller.
    fileprivate let barItems = MutableProperty(BarItems?.none)
}

extension NavigationBarViewController: UINavigationControllerDelegate
{
    // MARK: - Navigation Controller Delegate
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationControllerOperation,
        from fromVC: UIViewController,
        to toVC: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        return ComponentsTransitionController(duration: 0.5, components: [
            TranslationTransitionComponent(operation: operation),
            ActionTransitionComponent(animate: {
                self.viewControllers.value = navigationController.viewControllers
            })
        ])
    }
    
    func navigationController(
        navigationController: UINavigationController,
        interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning?
    {
        return nil
    }
}

enum RootNavigationItem: Int
{
    case cover
    case users
    case you
    case search
}

extension RootNavigationItem
{
    static var all: [RootNavigationItem]
    {
        return [.cover, .search, .users, .you]
    }

    fileprivate var viewController: BaseViewController
    {
        switch self
        {
        case .cover:
            return CoverViewController()
        case .users:
            return UsersViewController()
        case .you:
            return YouViewController()
        case .search:
            return SearchViewController()
        }
    }

    fileprivate var title: String
    {
        switch self
        {
        case .cover:
            return "Cover"
        case .users:
            return "Users"
        case .you:
            return "You"
        case .search:
            return "Search"
        }
    }

    fileprivate func barItem(currentRoot root: RootNavigationItem) -> BarItem
    {
        return BarItem(text: title, highlighted: root == self, action: .rootNavigation(self))
    }
}
