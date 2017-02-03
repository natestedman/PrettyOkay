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

import ReactiveCocoa
import ReactiveSwift
import PrettyOkayKit
import UIKit
import enum Result.NoError
import func Tuplex.unwrap

final class UserView: UIView
{
    // MARK: - Model

    /// The display data type for a user view.
    typealias Model = (user: User, isCurrentUser: Bool, fallbackAvatarImage: LoadedImage?)

    /// The product displayed by the view.
    let model = MutableProperty(Model?.none)

    // MARK: - Subviews

    /// The view surrounding the avatar view, providing a white overlay on the cover when scrolling.
    fileprivate let avatarBackgroundView = UIView(frame: .zero)

    /// The image view displaying the user's avatar.
    fileprivate let avatarImageView = ImageView(frame: .zero)

    /// The image view displaying the user's cover photo.
    fileprivate let coverImageView = HeaderImageView(frame: .zero)

    /// Contains labels displaying information about the user.
    fileprivate let detailsView = DetailTextView(frame: .zero)

    /// If the user is the current user, allows the user to modify his or her settings.
    fileprivate let settingsButton = UIButton(frame: .zero)

    /// A separator view at the bottom of the view.
    fileprivate let separator = UIView(frame: .zero)

    // MARK: - Initialization
    private func setup()
    {
        avatarBackgroundView.backgroundColor = .white
        avatarBackgroundView.layer.cornerRadius = 2

        func settingsAttributedString(_ color: UIColor) -> NSAttributedString
        {
            return NSAttributedString(string: "Settings", attributes: [
                NSFontAttributeName: UIFont.standard(),
                NSForegroundColorAttributeName: color
            ])
        }

        settingsButton.setAttributedTitle(settingsAttributedString(.normalControlColor), for: .normal)
        settingsButton.setAttributedTitle(settingsAttributedString(.highlightedControlColor), for: .highlighted)

        separator.backgroundColor = .separatorColor

        [coverImageView, avatarBackgroundView, avatarImageView, detailsView, settingsButton, separator]
            .forEach(addSubview)

        model.producer.startWithValues({ [weak self] model in
            self?.avatarImageView.loader.fallbackImage.value = model?.fallbackAvatarImage
            self?.avatarImageView.loader.imageURL.value = model?.user.avatarURL
            self?.coverImageView.loader.imageURL.value = model?.user.coverURL

            self?.detailsView.data.value = (model?.user).map({ user in
                (
                    title: user.name ?? user.username,
                    details: user.detailsAttributedString,
                    buttonEnabled: user.URL != nil
                )
            })

            let showSettings = model?.isCurrentUser ?? false
            self?.settingsButton.isHidden = !showSettings

            self?.setNeedsLayout()
        })
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

    // MARK: - Sizing
    private static let coverHeight: CGFloat = 250
    private static let avatarSize: CGFloat = 80

    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        let insetSize = CGSize(width: size.width - Layout.sidePadding * 2, height: size.height)

        let coverHeight = model.value?.user.coverURL != nil ? UserView.coverHeight : 0
        let avatarHeight = UserView.avatarSize + Layout.sidePadding * 2
        let detailsHeight = detailsView.sizeThatFits(insetSize).height

        let settingsHeight = (model.value?.isCurrentUser ?? false)
            ? settingsButton.sizeThatFits(insetSize).height + Layout.sidePadding
            : 0

        return CGSize(
            width: insetSize.width,
            height: coverHeight + avatarHeight + detailsHeight + settingsHeight
        )
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        let bounds = self.bounds

        let haveCover = model.value?.user.coverURL != nil

        coverImageView.bounds = haveCover
            ? CGRect(x: 0, y: 0, width: bounds.size.width, height: UserView.coverHeight)
            : .zero

        coverImageView.center = haveCover
            ? CGPoint(x: bounds.size.width / 2, y: UserView.coverHeight / 2)
            : .zero

        avatarImageView.frame = CGRect(
            x: round(bounds.midX - UserView.avatarSize / 2),
            y: coverImageView.frame.maxY + Layout.sidePadding,
            width: UserView.avatarSize,
            height: UserView.avatarSize
        )

        avatarBackgroundView.frame = avatarImageView.frame.insetBy(dx: -5, dy: -5)

        let detailsY = avatarImageView.frame.maxY + Layout.sidePadding
        let detailsSize = detailsView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        detailsView.frame = CGRect(
            x: Layout.sidePadding,
            y: detailsY,
            width: bounds.size.width - Layout.sidePadding * 2,
            height: detailsSize.height
        )

        let settingsY = detailsView.frame.maxY
        let settingsSize = settingsButton.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        settingsButton.frame = CGRect(
            x: Layout.sidePadding,
            y: settingsY,
            width: bounds.size.width - Layout.sidePadding * 2,
            height: settingsSize.height
        )

        let separatorHeight = Layout.separatorThickness

        separator.frame = CGRect(
            x: Layout.sidePadding,
            y: bounds.size.height - separatorHeight,
            width: bounds.size.width - Layout.sidePadding * 2,
            height: separatorHeight
        )
    }

    // MARK: - Scroll Effect
    var yContentOffset: CGFloat = 0
    {
        didSet
        {
            let coverHeight = UserView.coverHeight

            if yContentOffset >= 0
            {
                let fraction = min(yContentOffset / (coverHeight + UserView.avatarSize), 1)
                coverImageView.transform = CGAffineTransform(translationX: 0, y: UserView.avatarSize * fraction)
            }
            else
            {
                let scale = (coverHeight - yContentOffset) / coverHeight

                coverImageView.transform = CGAffineTransform(translationX: 0, y: yContentOffset / 2)
                    .scaledBy(x: scale, y: scale)
            }
        }
    }
}

extension Reactive where Base: UserView
{
    var detailsTapped: Signal<User, NoError>
    {
        return base.model.signal.sample(on: base.detailsView.reactive.buttonTapped).skipNil().map({ $0.user })
    }

    var settingsTapped: Signal<UIButton, NoError>
    {
        return base.settingsButton.reactive.controlEvents(.touchUpInside)
    }
}

extension User
{
    fileprivate var detailsAttributedString: NSAttributedString?
    {
        // the first path component is "/", drop that
        let URLString = unwrap(URL?.host, URL?.pathComponents.dropFirst()).map({ host, components in
            ([host] + components).joined(separator: "/")
        })

        let details = [
            location.map({
                NSAttributedString(string: $0, attributes: [
                    NSFontAttributeName: UIFont.standard(weight: UIFontWeightThin)
                ])
            }),
            URLString.map({
                NSAttributedString(string: $0, attributes: [
                    NSFontAttributeName: UIFont.standard()
                ])
            })
        ].flatMap({ $0 })

        return details.count > 0 ? details.separatedDetailsAttributedString : nil
    }
}
