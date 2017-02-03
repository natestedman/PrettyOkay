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

import CoreGraphics

/// Contains layout constants.
struct Layout
{
    private init() {}

    // MARK: - Padding Dimensions

    /// The amount that interface elements should be inset from the sides of the screen.
    static let sidePadding: CGFloat = 10

    // MARK: - Element Dimensions

    /// The thickness of separator line views.
    static let separatorThickness: CGFloat = UIScreen.main.pixelSize

    // MARK: - Bar Dimensions

    /// The size of top and bottom bars.
    static let navigationBarHeight: CGFloat = 60
}
