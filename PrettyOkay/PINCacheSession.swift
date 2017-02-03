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

import PINCache
import ReactiveSwift
import Shirley
import enum Result.NoError

// MARK: - Structure

/// A session backed by a `PINCache` instance, which will automatically fetch values (and store them in the cache) as
/// is necessary.
struct PINCacheSession<Request, Value: NSCoding, Error: Swift.Error>
{
    /// The cache to use.
    let cache: PINCache

    /// A function to create a cache key from a request.
    let makeKey: (Request) -> String

    /// A function to create a retrieval producer from a request.
    let retrieve: (Request) -> SignalProducer<Value, Error>
}

// MARK: - Session Type
extension PINCacheSession: SessionProtocol
{
    func producer(for request: Request) -> SignalProducer<Value, Error>
    {
        let key = makeKey(request)

        return cacheProducer(forKey: key)
            .flatMap(.concat, transform: { optional in
                optional.map({ SignalProducer(value: $0) }) ??
                    self.retrieve(request).on(value: { value in
                        self.cache.setObject(value, forKey: key)
                    })
            })
    }

    private func cacheProducer(forKey key: String) -> SignalProducer<Value?, NoError>
    {
        return SignalProducer { observer, _ in
            self.cache.object(forKey: key, block: { _, _, value in
                observer.send(value: flatten(value as? Value))
                observer.sendCompleted()
            })
        }
    }
}

// MARK: - Utilities
func flatten<Value>(_ value: Value??) -> Value?
{
    switch value
    {
    case let .some(o):
        return o
    case .none:
        return .none
    }
}
