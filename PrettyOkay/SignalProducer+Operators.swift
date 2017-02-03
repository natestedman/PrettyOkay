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

extension SignalProducerProtocol
{
    /// Converts an erroring signal to a signal that instead sends `Result` objects.
    func results() -> SignalProducer<Result<Value, Error>, NoError>
    {
        return map(Result.success).flatMapError({ SignalProducer(value: Result.failure($0)) })
    }
}

extension SignalProducerProtocol where Value: OptionalProtocol
{
    /// Maps non-`nil` values of the receiver, passing `nil` values through.
    ///
    /// - parameter transform: A transform function.
    func mapOptional<Other>(_ transform: @escaping (Value.Wrapped) -> Other) -> SignalProducer<Other?, Error>
    {
        return map({ optional in
            if let value = optional.optional
            {
                return transform(value)
            }
            else
            {
                return nil
            }
        })
    }

    /// `flatMap`s non-`nil` values of the receiver, passing `nil` values through as a single `nil` value.
    ///
    /// - parameter strategy:  The flatten strategy to use.
    /// - parameter transform: A transform function.
    func flatMapOptional<Other>(_ strategy: FlattenStrategy,
                                transform: @escaping (Value.Wrapped) -> SignalProducer<Other, Error>)
        -> SignalProducer<Other?, Error>
    {
        return flatMap(strategy, transform: { optional -> SignalProducer<Other?, Error> in
            if let value = optional.optional
            {
                return transform(value).map({ x in x })
            }
            else
            {
                return SignalProducer(value: nil)
            }
        })
    }
}
