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

final class AboutViewController: BaseViewController
{
    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        let textView = UITextView.newAutoLayout()
        textView.isEditable = false
        textView.isSelectable = true
        textView.indicatorStyle = .black
        textView.attributedText = AboutViewController.loadAttributedAboutText()
        textView.dataDetectorTypes = .link

        textView.textContainerInset = UIEdgeInsets(
            top: Layout.sidePadding,
            left: Layout.sidePadding,
            bottom: Layout.sidePadding,
            right: Layout.sidePadding
        )

        view.addSubview(textView)
        textView.autoPinEdgesToSuperviewEdges()
    }

    private static func loadAttributedAboutText() -> NSAttributedString
    {
        let string = NSMutableAttributedString()

        let titleFont = UIFont.standard(weight: UIFontWeightSemibold)
        let bodyFont = UIFont.standard()

        if let URL = Bundle.main.url(forResource: "About", withExtension: "plist"),
             let about = NSArray(contentsOf: URL) as? [[String:String]]
        {
            for dictionary in about.dropLast()
            {
                string.append(dictionary: dictionary, titleFont: titleFont, bodyFont: bodyFont, bodySuffix: "\n\n")
            }

            if let dictionary = about.last
            {
                string.append(dictionary: dictionary, titleFont: titleFont, bodyFont: bodyFont, bodySuffix: "")
            }
        }

        return string
    }
}

extension NSMutableAttributedString
{
    fileprivate func append(dictionary: [String:String],
                            titleFont: UIFont,
                            bodyFont: UIFont,
                            bodySuffix: String)
    {
        if let title = dictionary["Title"], let body = dictionary["Body"]
        {
            append(NSAttributedString(string: title + "\n\n", attributes: [
                NSFontAttributeName: titleFont
            ]))

            append(NSAttributedString(string: body + bodySuffix, attributes: [
                NSFontAttributeName: bodyFont
            ]))
        }
    }
}
