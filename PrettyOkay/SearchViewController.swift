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
import ReactiveSwift
import UIKit
import func Tuplex.unwrap

final class SearchViewController: ProductGridViewController
{
    fileprivate let searchField = UITextField.newAutoLayout()

    fileprivate let query = MutableProperty<String?>(
        userDefaults: UserDefaults.standard,
        key: "SearchQuery",
        fromValue: { $0 },
        toValue: { $0 as? String }
    )

    override func pinCollectionViewToTop(_ collectionView: UIView)
    {
        let searchBar = UIView.newAutoLayout()
        searchBar.backgroundColor = .white
        view.addSubview(searchBar)
        searchBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        searchBar.autoSetDimension(.height, toSize: 60)

        searchField.text = query.value
        searchField.delegate = self
        searchField.placeholder = "Search"
        searchField.returnKeyType = .search
        searchField.autocapitalizationType = .none
        searchField.autocorrectionType = .no
        searchField.clearButtonMode = .always
        searchBar.addSubview(searchField)

        searchField.autoPinEdge(toSuperviewEdge: .left, withInset: Layout.sidePadding)
        searchField.autoPinEdge(toSuperviewEdge: .right, withInset: Layout.sidePadding)
        searchField.autoAlignAxis(toSuperviewAxis: .horizontal)

        let searchBarSeparator = UIView.newAutoLayout()
        searchBarSeparator.backgroundColor = UIColor.separatorColor
        view.addSubview(searchBarSeparator)

        searchBarSeparator.autoPinEdge(toSuperviewEdge: .left)
        searchBarSeparator.autoPinEdge(toSuperviewEdge: .right)
        searchBarSeparator.autoSetDimension(.height, toSize: Layout.separatorThickness)
        searchBarSeparator.autoPinEdge(.top, to: .bottom, of: searchBar)
        searchBarSeparator.autoPinEdge(.bottom, to: .top, of: collectionView)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        reactive.trigger(for: #selector(viewDidAppear(_:))).take(first: 1).observeValues({ [weak self] in
            guard let count = self?.searchField.text?.characters.count, count == 0 else { return }
            self?.searchField.becomeFirstResponder()
        })

        arrayLoader <~ query.producer
            .map({ ($0?.characters.count ?? 0) > 0 ? $0 : nil })
            .skipRepeats(==)
            .combineLatest(with: api.producer)
            .map(unwrap)
            .mapOptional({ query, API in
                API.searchArrayLoader(query: query, limit: 20)
            })
            .map({ $0 ?? AnyArrayLoader(StaticArrayLoader.empty).promoteErrors(NSError.self) })
    }
}

extension SearchViewController: UITextFieldDelegate
{
    func textFieldShouldClear(_ textField: UITextField) -> Bool
    {
        query.value = nil
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        query.value = textField.text
        textField.resignFirstResponder()
        return false
    }
}
