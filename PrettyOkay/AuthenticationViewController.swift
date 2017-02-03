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
import UIKit
import enum Result.NoError
import func Tuplex.unwrap

/// Displays the authentication interface.
final class AuthenticationViewController: BaseViewController
{
    // MARK: - Subviews
    fileprivate let authenticationView = AuthenticationView.newAutoLayout()
    fileprivate let activityView = UIActivityIndicatorView.newAutoLayout()

    // MARK: - State
    private let performingAuthentication = MutableProperty(false)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view

        authenticationView.username.delegate = self
        authenticationView.password.delegate = self
        view.addSubview(authenticationView)

        authenticationView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        authenticationView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
        authenticationView.autoPinEdge(toSuperviewEdge: .leading)
        authenticationView.autoPinEdge(toSuperviewEdge: .trailing)

        activityView.activityIndicatorViewStyle = .gray
        view.addSubview(activityView)
        activityView.autoCenterInSuperview()
        activityView.startAnimating()

        // update interface when performing authentication
        performingAuthentication.producer.startWithValues({ [weak self] performingAuthentication in
            guard let strong = self else { return }
            strong.activityView.alpha = performingAuthentication ? 1 : 0
            strong.authenticationView.isUserInteractionEnabled = !performingAuthentication
            strong.authenticationView.alpha = performingAuthentication ? 0 : 1
        })
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // enable 1password extension
        let onePassword = OnePasswordExtension.shared()
        authenticationView.showOnePassword <~ onePassword.reactive.available

        authenticationView.onePasswordButton.reactive.controlEvents(.touchUpInside)
            .flatMap(.concat, transform: { [weak self] sender -> SignalProducer<(username: String, password: String), NoError> in
                guard let strong = self else { return SignalProducer.empty }

                return onePassword.reactive.findLogin(urlString: "verygoods.co", inViewController: strong, sender: sender)
                    .flatMapError({ error in
                        print("1Password error: \(error)")
                        return SignalProducer.empty
                    })
            })
            .observeValues({ [weak authenticationView] username, password in
                authenticationView?.username.text = username
                authenticationView?.password.text = password
                authenticationView?.loginButton.sendActions(for: .touchUpInside)
            })

        // perform login
        performingAuthentication <~ authenticationView.loginButton.reactive.controlEvents(.touchUpInside)
            // can't use sample here, as textProducer won't include the 1Password manual sets
            .map({ [weak authenticationView] _ in
                unwrap(authenticationView?.username.text, authenticationView?.password.text)
            })
            .skipNil()
            .flatMap(.latest, transform: { [weak self] username, password -> SignalProducer<Bool, NoError> in
                SignalProducer(value: true).concat(
                    AuthenticationController(username: username, password: password)
                        .authenticationProducer()
                        .observe(on: QueueScheduler.main)
                        .on(value: { [weak self] authentication in
                            self?.clients.value?.authenticate(authentication)
                        })
                        .map({ _ in true })
                        .flatMapError({ [weak self] error -> SignalProducer<Bool, NoError> in
                            if let strong = self
                            {
                                let alert = UIAlertController(
                                    title: error.localizedDescription,
                                    message: error.localizedFailureReason,
                                    preferredStyle: .alert
                                )

                                alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

                                strong.present(alert, animated: true, completion: nil)
                            }

                            return SignalProducer(value: false)
                        })
                )
            })
    }
}

extension AuthenticationViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField == authenticationView.username
        {
            authenticationView.password.becomeFirstResponder()
        }
        else if textField == authenticationView.password
        {
            authenticationView.username.becomeFirstResponder()
        }

        return false
    }
}
