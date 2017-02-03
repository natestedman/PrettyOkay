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
import Result
import func Tuplex.unwrap

extension Reactive where Base: OnePasswordExtension
{
    /// A producer for the availability of 1Password.
    var available: SignalProducer<Bool, NoError>
    {
        // determine whether or not 1Password is currently available
        // this needs to be redetermined when the user leaves the app, since he or she could install the 1Password app
        // while this app is in the background
        let triggers = SignalProducer(value: ()).concat(
            SignalProducer(NotificationCenter.default.reactive.notifications(
                forName: NSNotification.Name.UIApplicationDidBecomeActive,
                object: UIApplication.shared
            ).map({ _ in () }))
        )

        // whenever a trigger occurs, determine whether or not 1Password is installed
        return triggers.map({ _ in self.base.isAppExtensionAvailable() }).skipRepeats()
    }

    /// A producer for presenting the 1Password interface and selecting a username and password.
    ///
    /// - parameter urlString:      The URL string to look up in 1Password.
    /// - parameter viewController: The view controller to present atop.
    /// - parameter sender:         The control that triggered the lookup.
    func findLogin(urlString: String,
                   inViewController viewController: UIViewController,
                   sender: AnyObject?)
        -> SignalProducer<(username: String, password: String), NSError>
    {
        return SignalProducer { observer, disposable in
            self.base.findLogin(
                forURLString: urlString,
                for: viewController,
                sender: sender,
                completion: { results, error in
                    disposable += SignalProducer(result: Result(
                        unwrap(results?[AppExtensionUsernameKey] as? String,
                               results?[AppExtensionPasswordKey] as? String)
                            .map({ (username: $0, password: $1) }),
                        failWith: (error ?? OnePasswordUnknownError()) as NSError
                    )).start(observer)
                }
            )
        }
    }
}

/// Sent if 1Password does not provide an error, but does not provide a username and password.
struct OnePasswordUnknownError: CustomNSError
{
    static let errorDomain = "OnePasswordUnknownError"
    let errorCode = 0
}
