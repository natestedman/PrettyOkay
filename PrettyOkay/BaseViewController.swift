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

/// A base class for view controllers in the app, allowing authentication information and clients to be shared.
class BaseViewController: UIViewController
{
    // MARK: - Clients

    /// The clients that can be assigned to a view controller, for loading and modifying data.
    struct Clients
    {
        /// The API client.
        let api: APIClient

        /// The want client - only present if a user is authenticated.
        let want: WantClient?

        /// An authentication callback, to be used for login and logout.
        let authenticate: (Authentication?) -> ()
    }

    /// The current clients assigned to the view controller.
    let clients = MutableProperty(Clients?.none)

    /// The current `APIClient` assigned to the view controller.
    private(set) lazy var api: Property<APIClient?> = { [unowned self] in
        self.clients.map({ $0?.api })
    }()

    /// The current `WantClient` assigned to the view controller.
    private(set) lazy var want: Property<WantClient?> = { [unowned self] in
        self.clients.map({ $0?.want })
    }()
}
