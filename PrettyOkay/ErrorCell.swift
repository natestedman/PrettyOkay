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

import ArrayLoaderInterface
import UIKit

class ErrorView: UIView
{
    private let textLabel = UILabel.newAutoLayout()
    private let detailLabel = UILabel.newAutoLayout()
    let button = UIButton.newAutoLayout()
    
    private func setup()
    {
        let container = UIView.newAutoLayout()
        self.addSubview(container)
        
        textLabel.numberOfLines = 4
        textLabel.font = UIFont.boldSystemFont(ofSize: 12)
        container.addSubview(textLabel)
        
        detailLabel.numberOfLines = 2
        detailLabel.font = UIFont.systemFont(ofSize: 12)
        container.addSubview(detailLabel)
        
        button.setTitle("Retry", for: .normal)
        self.addSubview(button)
        
        container.autoAlignAxis(toSuperviewAxis: .horizontal)
        container.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        
        textLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        detailLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        detailLabel.autoPinEdge(.top, to: .bottom, of: textLabel, withOffset: 5)
        
        button.autoAlignAxis(toSuperviewAxis: .horizontal)
        button.autoPinEdge(.left, to: .right, of: container, withOffset: 10)
        button.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    var error: NSError?
    {
        didSet
        {
            if let description = error?.localizedDescription, let failureReason = error?.localizedFailureReason
            {
                textLabel.text = description
                detailLabel.text = failureReason
            }
            else
            {
                textLabel.text = "Error"
                detailLabel.text = error?.localizedDescription ?? error?.localizedFailureReason
            }
        }
    }
}

protocol ErrorCellDelegate: class
{
    func errorCellTappedRetry(_ errorCell: ErrorCell)
}

class ErrorCell: UICollectionViewCell, ArrayLoaderErrorDisplaying
{
    weak var delegate: ErrorCellDelegate?
    
    private let errorView = ErrorView.newAutoLayout()
    
    private func setup()
    {
        contentView.addSubview(errorView)
        errorView.autoPinEdgesToSuperviewEdges()

        errorView.button.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.errorCellTappedRetry(strongSelf)
        })
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    var error: NSError?
    {
        didSet { errorView.error = error }
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        error = nil
        delegate = nil
    }
}
