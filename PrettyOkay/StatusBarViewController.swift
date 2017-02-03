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

import PureLayout
import UIKit

final class StatusBarViewController: UIViewController
{
    // MARK: - Subviews
    private let container = UIView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        let statusBar = UIView.newAutoLayout()
        statusBar.backgroundColor = .black
        view.addSubview(statusBar)
        view.addSubview(container)

        statusBar.autoSetDimension(.height, toSize: UIApplication.shared.statusBarFrame.size.height)
        statusBar.autoPinEdge(toSuperviewEdge: .leading)
        statusBar.autoPinEdge(toSuperviewEdge: .trailing)
        statusBar.autoPinEdge(.bottom, to: .top, of: container)

        container.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        container.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)

        let corners = (
            left: StatusBarCornerView.newAutoLayout(),
            right: StatusBarCornerView.newAutoLayout()
        )

        corners.right.side = .right

        [corners.left, corners.right].forEach({ corner in
            view.addSubview(corner)
            corner.autoPinEdge(.top, to: .bottom, of: statusBar)
            corner.autoSetDimensions(to: CGSize(width: 2, height: 2))
        })

        corners.left.autoPinEdge(toSuperviewEdge: .left)
        corners.right.autoPinEdge(toSuperviewEdge: .right)
    }

    // MARK: - Child Controller
    var contentViewController: UIViewController?
    {
        didSet(oldValue)
        {
            if let controller = oldValue
            {
                controller.willMove(toParentViewController: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
            }

            if let controller = contentViewController
            {
                addChildViewController(controller)
                container.addSubview(controller.view)
                controller.view.autoPinEdgesToSuperviewEdges()
                controller.didMove(toParentViewController: self)
            }
        }
    }

    // MARK: - Status Bar
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .lightContent
    }
}

private final class StatusBarCornerView: UIView
{
    enum Side { case left, right }
    var side = Side.left { didSet { setNeedsDisplay() } }

    // MARK: - Initialization
    private func setup()
    {
        backgroundColor = .clear
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let bounds = self.bounds

        context.addRect(bounds)
        context.addEllipse(
            in: side == .left
                ? CGRect(
                    x: 0,
                    y: 0,
                    width: bounds.size.width * 2,
                    height: bounds.size.height * 2
                )
                : CGRect(
                    x: -bounds.size.width,
                    y: 0,
                    width: bounds.size.width * 2,
                    height: bounds.size.height * 2
                )
        )

        context.setFillColor(gray: 0, alpha: 1)
        context.fillPath(using: .evenOdd)
    }
}
