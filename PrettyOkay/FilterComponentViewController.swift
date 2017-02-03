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
import Tuplex
import UIKit

/// Displays an interface to select items of a `FilterComponent`.
final class FilterComponentViewController<Component: FilterComponent>:
    UIViewController, UITableViewDataSource, UITableViewDelegate
{
    // MARK: - Initialization

    /// Appease generics.
    convenience init() { self.init(nibName: nil, bundle: nil) }

    // MARK: - Selected Items

    /// All items in the component, cached for this instance.
    private let items = Component.all

    /// The currently selected items. This property can be modified to select or deselect items.
    let selectedItems = MutableProperty(Set<Component>())

    /// A flag to prevent table view re-selection.
    private var tableViewIsModifyingSelectedItems = false

    private func tableViewModifySelectedItems(_ function: (Set<Component>) -> Set<Component>)
    {
        tableViewIsModifyingSelectedItems = true
        selectedItems.modify({ $0 = function($0) })
        tableViewIsModifyingSelectedItems = false
    }

    /// If `true`, selection changes will be animated.
    var animateSelectionChanges = false

    // MARK: - Subviews

    /// The table view displaying the component's items.
    private let tableView = UITableView.newAutoLayout()

    /// A container for the table view, necessary for making masking work with scroll views.
    private let tableViewMaskContainer = UIView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add mask container
        view.addSubview(tableViewMaskContainer)

        tableViewMaskContainer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(
            top: rowHeight - maskInset,
            left: 0,
            bottom: 0,
            right: 0
        ))

        tableViewMaskContainer.mask = TableMaskView()

        // add table view
        tableView.register(cellType: FilterItemCell.self)
        tableView.allowsMultipleSelection = true
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.rowHeight = rowHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: maskInset, left: 0, bottom: maskInset, right: 0)

        tableViewMaskContainer.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()

        // add top label
        let labelContainer = UIView.newAutoLayout()
        view.addSubview(labelContainer)

        labelContainer.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        labelContainer.autoSetDimension(.height, toSize: rowHeight)

        let label = UILabel.newAutoLayout()
        label.font = .standard(weight: UIFontWeightMedium)
        label.text = Component.title
        labelContainer.addSubview(label)

        label.autoPinEdge(toSuperviewEdge: .left)
        label.autoPinEdge(toSuperviewEdge: .right)
        label.autoAlignAxis(toSuperviewAxis: .horizontal)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        selectedItems.producer.startWithValues({ [weak self] selected in
            guard let strong = self, !strong.tableViewIsModifyingSelectedItems else { return }

            if let current = strong.tableView.indexPathsForSelectedRows
            {
                current.map({ ($0, strong.items[$0.row]) }).forEach({ path, category in
                    if !selected.contains(category)
                    {
                        strong.tableView.deselectRow(at: path, animated: strong.animateSelectionChanges)
                    }
                })
            }

            selected.flatMap({ strong.items.index(of: $0) }).forEach({
                strong.tableView.selectRow(
                    at: IndexPath(row: $0, section: 0),
                    animated: strong.animateSelectionChanges,
                    scrollPosition: .none
                )
            })
        })
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()

        tableViewMaskContainer.mask?.frame = tableViewMaskContainer.bounds
    }

    // MARK: - Table View Data Source
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return items.count
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: FilterItemCell = tableView.dequeue(indexPath: indexPath)
        cell.itemText = "\(items[indexPath.row])"
        return cell
    }

    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableViewModifySelectedItems { $0.union([items[indexPath.row]]) }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        tableViewModifySelectedItems { $0.subtracting([items[indexPath.row]]) }
    }
}

private let rowHeight: CGFloat = 50
private let maskInset: CGFloat = 10

private final class TableMaskView: UIView
{
    // MARK: - Initialization
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - Drawing
    private func makeGradient() -> CGGradient?
    {
        let components: [CGFloat] = [0, 0, 0, 1]
        let locations: [CGFloat] = [0, 1]

        return components.withUnsafeBufferPointer({ componentsPtr in
            locations.withUnsafeBufferPointer({ locationsPtr in
                unwrap(componentsPtr.baseAddress, locationsPtr.baseAddress).flatMap({ componentsAddr, locationsAddr in
                    CGGradient(
                        colorSpace: CGColorSpaceCreateDeviceGray(),
                        colorComponents: componentsAddr,
                        locations: locationsAddr,
                        count: 2
                    )
                })
            })
        })
    }

    override func draw(_ rect: CGRect)
    {
        guard let gradient = makeGradient(), let context = UIGraphicsGetCurrentContext() else { return }

        let size = bounds.size

        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: maskInset), options: [])
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: size.height - maskInset), options: [])

        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: maskInset, width: size.width, height: size.height - maskInset * 2))
    }
}
