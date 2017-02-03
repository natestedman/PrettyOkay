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
import UIKit
import enum Result.NoError
import func Tuplex.unwrap

/// Displays the cover of Very Goods.
final class CoverViewController: ProductGridViewController
{
    // MARK: - Filters

    /// The filters to apply to the cover.
    fileprivate let filters: MutableProperty<Filters> = MutableProperty(
        userDefaults: UserDefaults.standard,
        key: "CoverFilters",
        fromValue: { $0.encoded },
        toValue: { (try? Filters(anyEncoded: $0)) ?? Filters() }
    )

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = "Cover"

        let filtersProducer = filters.producer.map({ $0.simplified() }).skipRepeats()

        self.arrayLoader <~ SignalProducer.combineLatest(api.producer, filtersProducer).map({ optionalAPI, filters in
            guard let API = optionalAPI else { return StaticArrayLoader.empty.promoteErrors(NSError.self) }
            
            let loadStategy = API.productsLoadStrategy(filters: filters, limit: 40)
            return AnyArrayLoader(StrategyArrayLoader(load: loadStategy))
        })
    }
}

extension CoverViewController: BarActionsProvider
{
    var barActionsProducer: SignalProducer<[BarItem], NoError>
    {
        return filters.filtersBarActionsProducer
    }
}
