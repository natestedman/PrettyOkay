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

import UIKit

extension UITableView
{
    // MARK: - Registering Cell Types

    /// Yields the built-in reuse identifier for the specified cell type.
    ///
    /// - parameter cellType: The cell type.
    private func reuseIdentifier<T: UITableViewCell>(cellType: T.Type) -> String
    {
        return "PrettyOkay-\(cellType)"
    }

    /// Registers the cell type for use with `dequeue(indexPath:)`.
    ///
    /// - parameter cellType: The cell type.
    func register<T: UITableViewCell>(cellType: T.Type)
    {
        register(cellType, forCellReuseIdentifier: reuseIdentifier(cellType: cellType))
    }

    /// Dequeues a cell from the receiver. The cell type should have been previous registered with the
    /// `register(cellType:)` method.
    ///
    /// - parameter indexPath: The index path of the cell to dequeue.
    func dequeue<T: UITableViewCell>(indexPath: IndexPath) -> T
    {
        return dequeueReusableCell(withIdentifier: reuseIdentifier(cellType: T.self), for: indexPath) as! T
    }
}
