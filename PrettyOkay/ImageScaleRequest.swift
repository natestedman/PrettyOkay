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

import Foundation

// MARK: - Structure

/// A structure encapsulating a scaled image request.
struct ImageScaleRequest
{
    /// The URL of the image to load.
    let url: URL

    /// The scale factor to draw the image at.
    let scale: CGFloat

    /// The size to draw the image at.
    let size: CGSize
}

// MARK: - Hashable
extension ImageScaleRequest: Hashable
{
    var hashValue: Int
    {
        return url.hashValue ^ scale.hashValue ^ size.width.hashValue ^ size.height.hashValue
    }
}

// MARK: - Equatable
func ==(lhs: ImageScaleRequest, rhs: ImageScaleRequest) -> Bool
{
    return lhs.url == rhs.url && lhs.scale == rhs.scale && lhs.size == rhs.size
}
