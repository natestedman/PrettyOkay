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
import ReactiveSwift
import PrettyOkayKit
import UIKit

final class AuthenticationView: UIView
{
    // MARK: - Fields
    private let fields = AuthenticationView.makeFields()
    var username: UITextField { return fields.username.field }
    var password: UITextField { return fields.password.field }

    // MARK: - Buttons
    private let buttons = AuthenticationView.makeButtons()
    var loginButton: UIButton { return buttons.login }
    var onePasswordButton: UIButton { return buttons.onePassword }

    // MARK: - 1Password
    let showOnePassword = MutableProperty(true)

    // MARK: - Initialization
    private func setup()
    {
        let stack = UIStackView.newAutoLayout()
        stack.alignment = .fill
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = 20
        addSubview(stack)

        [fields.title, fields.username, fields.password, buttons.view].forEach(stack.addArrangedSubview)

        [ALEdge.leading, .trailing].forEach({
            stack.autoPinEdge(toSuperviewEdge: $0, withInset: 20, relation: .greaterThanOrEqual)
        })

        stack.autoAlignAxis(toSuperviewAxis: .vertical)
        stack.autoPinEdge(toSuperviewEdge: .top, withInset: 20)

        NSLayoutConstraint.autoSetPriority(UILayoutPriorityDefaultHigh, forConstraints: {
            stack.autoSetDimension(.width, toSize: 330)
        })

        showOnePassword.producer.startWithValues({ [weak self] available in
            self?.onePasswordButton.isUserInteractionEnabled = available
            self?.onePasswordButton.isHidden = !available
            self?.onePasswordButton.isAccessibilityElement = available
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

    private static func makeFields()
        -> (title: UIView, username: AuthenticationViewField, password: AuthenticationViewField)
    {
        let font = UIFont.systemFont(ofSize: fontSize)
        let placeholderAttributes = [NSForegroundColorAttributeName: UIColor.normalControlColor]

        let title = UILabel.newAutoLayout()
        title.numberOfLines = 0

        let titleText = NSMutableAttributedString(
            string: "Sign in with your ",
            attributes: [NSFontAttributeName: font]
        )

        titleText.append(
            NSAttributedString(string: "Very Goods", attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightSemibold)
            ])
        )

        titleText.append(
            NSAttributedString(string: " account.", attributes: [NSFontAttributeName: font])
        )

        title.attributedText = titleText

        let titleContainer = UIView.newAutoLayout()
        titleContainer.addSubview(title)
        title.autoPinEdgesToSuperviewEdges(with: UIEdgeInsetsMake(0, 0, 10, 0))

        let username = AuthenticationViewField.newAutoLayout()
        username.field.font = font
        username.field.attributedPlaceholder = NSAttributedString(string: "Username", attributes: placeholderAttributes)
        username.field.autocapitalizationType = .none
        username.field.autocorrectionType = .no
        username.field.returnKeyType = .next

        let password = AuthenticationViewField.newAutoLayout()
        password.field.font = font
        password.field.attributedPlaceholder = NSAttributedString(string: "Password", attributes: placeholderAttributes)
        password.field.isSecureTextEntry = true
        password.field.returnKeyType = .next

        return (title: titleContainer, username: username, password: password)
    }

    private static func makeButtons() -> (view: UIView, login: UIButton, onePassword: UIButton)
    {
        let view = UIView.newAutoLayout()

        let loginButton = UIButton.newAutoLayout()

        func loginAttributedString(_ color: UIColor) -> NSAttributedString
        {
            return NSAttributedString(string: "Login →", attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: fontSize),
                NSForegroundColorAttributeName: color
            ])
        }

        loginButton.setAttributedTitle(loginAttributedString(.normalControlColor), for: .normal)
        loginButton.setAttributedTitle(loginAttributedString(.highlightedControlColor), for: .highlighted)

        view.addSubview(loginButton)

        let onePasswordButton = UIButton.newAutoLayout()
        onePasswordButton.accessibilityLabel = "Use 1Password"

        let onePasswordImage = UIImage(named: "onepassword-navbar")?.withRenderingMode(.alwaysTemplate)
        onePasswordButton.setImage(onePasswordImage, for: .normal)
        onePasswordButton.tintColor = UIColor.normalControlColor
        view.addSubview(onePasswordButton)

        [loginButton, onePasswordButton].forEach({ button in
            view.addSubview(button)

            button.autoPinEdge(toSuperviewEdge: .top, withInset: 0, relation: .greaterThanOrEqual)
            button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
            button.autoAlignAxis(toSuperviewAxis: .horizontal)
        })

        loginButton.autoPinEdge(toSuperviewEdge: .leading)
        onePasswordButton.autoPinEdge(toSuperviewEdge: .trailing)

        return (view: view, login: loginButton, onePassword: onePasswordButton)
    }
}

private final class AuthenticationViewField: UIView
{
    // MARK: - Field
    fileprivate let field = UITextField.newAutoLayout()

    // MARK: - Initialization
    private func setup()
    {
        addSubview(field)
        field.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)

        let separator = UIView.newAutoLayout()
        separator.backgroundColor = UIColor.normalControlColor
        addSubview(separator)

        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        separator.autoPinEdge(.top, to: .bottom, of: field, withOffset: 4)
        separator.autoSetDimension(.height, toSize: Layout.separatorThickness)
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
}

private let fontSize: CGFloat = 18
