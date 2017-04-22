//
//  UIPlaceholderTextView.swift
//  Heartland Chefs
//
//  Created by Hai Pham on 10/11/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import RxSwift
import RxCocoa
import SwiftUtilities
import SwiftUIUtilities
import UIKit

public final class UIPlaceholderTextView: UIView {
    
    /// This UITextView is used for multi-line text edits. Usually it does
    /// not have a placeholder property.
    @IBOutlet fileprivate weak var textView: UITextView!
    
    /// This UILabel shall serve as the placeholder view for the UITextView.
    @IBOutlet fileprivate weak var placeholderView: UILabel!
    
    /// Pass this to textView and placeholderView.
    @IBInspectable public var fontName: String? {
        didSet {
            (textView as? DynamicFontType)?.fontName = fontName
            (placeholderView as? DynamicFontType)?.fontName = fontName
        }
    }
    
    /// Pass this to textView and placeholderView.
    @IBInspectable public var fontSize: String? {
        didSet {
            (textView as? DynamicFontType)?.fontSize = fontSize
            (placeholderView as? DynamicFontType)?.fontSize = fontSize
        }
    }
    
    /// Lazy presenter initialization.
    fileprivate lazy var presenter: Presenter = Presenter(view: self)
    
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
        presenter.awakeFromNib(self)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        presenter.layoutSubviews(self)
    }
    
    /// Presenter for UIPlaceholderTextView
    fileprivate class Presenter: BaseViewPresenter {
        
        /// Dispose of subscribed Observables when deinit() is called.
        fileprivate let disposeBag: DisposeBag
        
        /// Set this to true once all subviews have been laid out.
        fileprivate lazy var initialized = false
        
        /// Watch for backgroundColor to transfer to the first subview, since
        /// we initialized this UIView with a Nib.
        fileprivate let bgColorVariable: Variable<UIColor?>
        
        fileprivate init(view: UIPlaceholderTextView) {
            disposeBag = DisposeBag()
            bgColorVariable = Variable<UIColor?>(view.backgroundColor)
            super.init(view: view)
        }
        
        override func awakeFromNib(_ view: UIView) {
            super.awakeFromNib(view)
            view.backgroundColor = .clear
        }
        
        override func layoutSubviews(_ view: UIView) {
            super.layoutSubviews(view)
            
            guard
                !initialized,
                let view = view as? UIPlaceholderTextView,
                let textView = view.textView,
                let placeholderView = view.placeholderView
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
                .doOnNext(textDidChange)
                .subscribe()
                .addDisposableTo(disposeBag)
            
            bgColorVariable
                .asObservable()
                .doOnNext({view.subviews.first?.backgroundColor = $0})
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
    /// Pass this to textView and placeholderView.
    public var activeFont: UIFont? {
        get { return nil }
        
        set {
            (textView as? DynamicFontType)?.activeFont = newValue
            (placeholderView as? DynamicFontType)?.activeFont = newValue
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
    
    /// Return the text as dislayed by placeholderView. This text is used as
    /// the placeholder.
    @IBInspectable public var placeholder: String? {
        get { return placeholderView?.text }
        set { placeholderView?.text = newValue }
    }
    
    /// Set placeholderView's textColor property.
    public var placeholderTextColor: UIColor? {
        get { return placeholderView?.textColor }
        set { placeholderView?.textColor = newValue }
    }
    
    /// Override super tintColor to return placeholderView's tintColor.
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
    public var rxText: ControlProperty<String?>? {
        return textView?.rx.text
    }
}

fileprivate extension UIPlaceholderTextView.Presenter {
    
    /// Optionally cast viewDelegate to the current UIView subclass.
    var view: UIPlaceholderTextView? {
        return viewDelegate as? UIPlaceholderTextView
    }
}

fileprivate extension UIPlaceholderTextView.Presenter {
    
    /// This method will be called when the textView's text is changed.
    ///
    /// - Parameter text: The new text as displayed by the textView.
    fileprivate func textDidChange(to text: String?) {
        guard let placeholderView = view?.placeholderView else {
            debugException()
            return
        }
        
        if let text = text, text.isNotEmpty, placeholderView.alpha > 0 {
            placeholderView.toggleVisible(toBe: false)
        } else if text == nil || (text!.isEmpty && placeholderView.alpha < 1) {
            placeholderView.toggleVisible(toBe: true)
        }
    }
}

public extension Reactive where Base: UIPlaceholderTextView {
    /// Add a text property to access textView's rx.text property.
    public var text: ControlProperty<String?> {
        guard let rxText = base.rxText else {
            fatalError()
        }
        
        return rxText
    }
}
