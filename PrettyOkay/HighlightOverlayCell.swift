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

class HighlightOverlayCell: HighlightCell
{
    var overlayColor = UIColor(white: 1.0, alpha: 0.3)
    {
        didSet
        {
            overlayView?.backgroundColor = overlayColor
        }
    }
    
    private var overlayView: UIView?
    
    override var shouldAppearHighlighted: Bool
    {
        didSet
        {
            if overlayView == nil && shouldAppearHighlighted
            {
                let view = UIView.newAutoLayout()
                view.backgroundColor = self.overlayColor
                self.contentView.addSubview(view)
                
                view.autoPinEdgesToSuperviewEdges()
                
                self.overlayView = view
            }
            else if overlayView != nil && !shouldAppearHighlighted
            {
                overlayView?.removeFromSuperview()
                overlayView = nil
            }
        }
    }
}
