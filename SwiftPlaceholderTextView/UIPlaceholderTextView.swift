//
//  UIPlaceholderTextView.swift
//  SwiftPlaceholderTextView
//
//  Created by Hai Pham on 10/11/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import RxSwift
import RxCocoa
import SwiftBaseViews
import SwiftUtilities
import SwiftUIUtilities
import UIKit

/// This text input class provides placeholder support for UITextView.
public final class UIPlaceholderTextView: UIView {
    
    /// This UITextView is used for multi-line text edits. Usually it does
    /// not have a placeholder property.
    @IBOutlet weak var textView: UITextView!
    
    /// This UILabel shall serve as the placeholder view for the UITextView.
    @IBOutlet weak var placeholderLabel: UILabel!
    
    /// Pass this to textView and placeholderLabel.
    @IBInspectable public var fontName: String? {
        didSet {
            (textView as? DynamicFontType)?.fontName = fontName
            (placeholderLabel as? DynamicFontType)?.fontName = fontName
        }
    }
    
    /// Pass this to textView and placeholderLabel.
    @IBInspectable public var fontSize: String? {
        didSet {
            (textView as? DynamicFontType)?.fontSize = fontSize
            (placeholderLabel as? DynamicFontType)?.fontSize = fontSize
        }
    }
    
    /// Lazy presenter initialization.
    lazy var presenter: Presenter = Presenter(view: self)
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeWithNib()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initializeWithNib()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        presenter.awakeFromNib(for: self)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        presenter.layoutSubviews(for: self)
    }
    
    /// Presenter for UIPlaceholderTextView
    class Presenter: BaseViewPresenter {
        
        /// Dispose of subscribed Observables when deinit() is called.
        let disposeBag = DisposeBag()
        
        /// Set this to true once all subviews have been laid out.
        lazy var initialized = false
        
        /// Watch for backgroundColor to transfer to the first subview, since
        /// we initialized this UIView with a Nib.
        let bgColorVariable: Variable<UIColor?>
        
        init(view: UIPlaceholderTextView) {
            bgColorVariable = Variable<UIColor?>(view.backgroundColor)
            super.init(view: view)
        }
        
        override func awakeFromNib(for view: UIView) {
            super.awakeFromNib(for: view)
            view.backgroundColor = .clear
        }
        
        override func layoutSubviews(for view: UIView) {
            super.layoutSubviews(for: view)
            
            guard
                !initialized,
                let view = view as? UIPlaceholderTextView,
                let textView = view.textView,
                let placeholderLabel = view.placeholderLabel
                else {
                    return
            }
            
            defer { initialized = true }
            
            // We need to use a UIEdgeInsets to remove the UITextView's
            // padding. Otherwise, its text will not align vertically with
            // other input views.
            textView.contentInset = UIEdgeInsets(top: 0,
                                                 left: -4,
                                                 bottom: 0,
                                                 right: -4)
            
            textView.addAccessory(CompletionAccessory.builder()
                .with(target: self)
                .with(selectorType: self)
                .with(confirmId: "confirm")
                .with(cancelId: "cancel")
                .build())
            
            // Listen to text change events.
            textView.rx.text
                .asObservable()
                .doOnNext({[weak self, weak view] in
                    self?.textDidChange(to: $0, with: view)
                })
                .subscribe()
                .addDisposableTo(disposeBag)
            
            bgColorVariable
                .asObservable()
                .doOnNext({[weak view] in
                    view?.subviews.first?.backgroundColor = $0
                })
                .subscribe()
                .addDisposableTo(disposeBag)
        }
        
        override func actionExecuted(sender: AnyObject, event: UIEvent) {
            switch sender {
            case let sender as UIBarButtonItem:
                switch sender.accessibilityIdentifier {
                case .some("cancel"):
                    view?.textView?.text = nil
                    fallthrough
                    
                case .some("confirm"):
                    view?.textView?.resignFirstResponder()
                    
                default:
                    break
                }
                
            default:
                super.actionExecuted(sender: sender, event: event)
                break
            }
        }
    }
}

extension UIPlaceholderTextView: DynamicFontType {
    /// Pass this to textView and placeholderLabel.
    public var activeFont: UIFont? {
        get { return nil }
        
        set {
            (textView as? DynamicFontType)?.activeFont = newValue
            (placeholderLabel as? DynamicFontType)?.activeFont = newValue
        }
    }
}

extension UIPlaceholderTextView: InputFieldType {
    
    /// Set typealias to UITextView to access its rx extensions.
    public typealias InputField = UITextView
    
    /// Return the text as displayed by textView.
    @IBInspectable public var text: String? {
        get { return textView?.text }
        set { textView?.text = newValue }
    }
    
    /// Return the text as dislayed by placeholderLabel. This text is used as
    /// the placeholder.
    @IBInspectable public var placeholder: String? {
        get { return placeholderLabel?.text }
        set { placeholderLabel?.text = newValue }
    }
    
    /// Set placeholderLabel's textColor property.
    public var placeholderTextColor: UIColor? {
        get { return placeholderLabel?.textColor }
        set { placeholderLabel?.textColor = newValue }
    }
    
    /// Return the placeholderLabel.
    public var placeholderView: UIView? {
        return placeholderLabel
    }
    
    /// When font is set, pass it to both textView and placeholderLabel.
    /// However the getter only accesses textView's font.
    public var font: UIFont? {
        get { return textView?.font }
        
        set {
            textView?.font = font
            placeholderLabel?.font = font
        }
    }
    
    /// When we set textAlignment, pass it to both textView and
    /// placeholderLabel.
    public var textAlignment: NSTextAlignment {
        get { return textView?.textAlignment ?? .left }
        
        set {
            textView?.textAlignment = newValue
            placeholderLabel?.textAlignment = newValue
        }
    }
    
    /// When we set autocorrectionType, pass it to textView.
    public var autocorrectionType: UITextAutocorrectionType {
        get { return textView?.autocorrectionType ?? .default }
        set { textView?.autocorrectionType = newValue }
    }
    
    /// Override super tintColor to return placeholderLabel's tintColor.
    override public var tintColor: UIColor! {
        get { return textView?.tintColor }
        set { textView?.tintColor = newValue }
    }
    
    /// Return the textView's textColor.
    public var textColor: UIColor? {
        get { return textView?.textColor }
        set { textView?.textColor = newValue }
    }
    
    /// Return the textView's keyboard type.
    public var keyboardType: UIKeyboardType {
        get { return textView?.keyboardType ?? .default }
        set { textView?.keyboardType = newValue }
    }
    
    /// Return the textView's isSecureTextEntry.
    public var isSecureTextEntry: Bool {
        get { return textView?.isSecureTextEntry ?? false }
        set { textView?.isSecureTextEntry = newValue }
    }
    
    /// Call textView's resignFirstResponder().
    ///
    /// - Returns: A Bool value.
    override public func resignFirstResponder() -> Bool {
        return textView?.resignFirstResponder() ?? false
    }
    
    /// Get textView's rx.text property.
    public var rxText: Observable<String?> {
        return textView?.rx.text.asObservable() ?? Observable.empty()
    }
}

extension UIPlaceholderTextView.Presenter {
    
    /// Optionally cast viewDelegate to the current UIView subclass.
    var view: UIPlaceholderTextView? {
        return viewDelegate as? UIPlaceholderTextView
    }
}

extension UIPlaceholderTextView.Presenter {
    
    /// This method will be called when the textView's text is changed.
    ///
    /// - Parameter text: The new text as displayed by the textView.
    func textDidChange(to text: String?, with view: UIPlaceholderTextView?) {
        guard let placeholderLabel = view?.placeholderLabel else {
            debugException()
            return
        }
        
        if let text = text, text.isNotEmpty, placeholderLabel.alpha > 0 {
            placeholderLabel.toggleVisible(toBe: false)
        } else if text == nil || (text!.isEmpty && placeholderLabel.alpha < 1) {
            placeholderLabel.toggleVisible(toBe: true)
        }
    }
}

public extension Reactive where Base: UIPlaceholderTextView {
    /// Add a text property to access textView's rx.text property.
    public var text: Observable<String?> {        
        return base.rxText
    }
}
