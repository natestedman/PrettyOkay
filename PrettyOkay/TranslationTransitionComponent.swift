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

import ReactiveSwift
import Result
import UIKit

struct TranslationTransitionComponent
{
    let operation: UINavigationControllerOperation
    
    init(operation: UINavigationControllerOperation)
    {
        self.operation = operation
    }
}

extension TranslationTransitionComponent: TransitionComponent
{
    func producer(context: UIViewControllerContextTransitioning, duration: TimeInterval) -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, _ in
            let from = context.viewController(forKey: UITransitionContextViewControllerKey.from)!
            let to = context.viewController(forKey: UITransitionContextViewControllerKey.to)!
            
            let fromInitialFrame = context.initialFrame(for: from)
            to.view.frame = context.finalFrame(for: to)
            to.view.layoutIfNeeded()
            
            context.containerView.addSubview(from.view)
            context.containerView.addSubview(to.view)
            
            if self.operation == UINavigationControllerOperation.none
            {
                context.completeTransition(true)
                observer.sendCompleted()
            }
            else
            {
                let direction: CGFloat = self.operation == .pop ? -1 : 1
                
                to.view.transform = CGAffineTransform(translationX: fromInitialFrame.size.width * direction, y: 0)
                
                UIView.animate(withDuration: duration, animations: {
                    from.view.transform = CGAffineTransform(translationX: -fromInitialFrame.size.width * direction, y: 0)
                    to.view.transform = .identity
                }, completion: { finished in
                    from.view.transform = .identity
                    observer.sendCompleted()
                })
            }
        }
    }
}
