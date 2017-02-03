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
import enum Result.NoError

extension MutablePropertyProtocol where Value == Filters
{
    var filtersBarActionsProducer: SignalProducer<[BarItem], NoError>
    {
        let action = BarItem.Action.presentFromBar({ [weak self] in
            let controller = FiltersViewController()

            if let filters = self?.value
            {
                controller.select(filters: filters, animated: false)
            }

            return BarPresentation(
                viewController: controller,
                completion: { [weak self] in
                    if let filters = controller.filtersProducer.first()?.value
                    {
                        self?.value = filters
                    }
                }
            )
        })

        return producer.map({ filters in
            [BarItem(
                text: filters.simplified() == Filters() ? "Filters" : "✓ Filters",
                highlighted: false,
                action: action
            )]
        })
    }
}

