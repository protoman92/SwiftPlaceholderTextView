//
//  PlaceholderTextView.swift
//  Heartland Chefs
//
//  Created by Hai Pham on 10/11/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import RxSwift
import RxCocoa
import SwiftUtilities
import UIKit

public class PlaceholderTextView: UIView {
    
    /// This UITextView is used for multi-line text edits. Usually it does
    /// not have a placeholder property.
    @IBOutlet fileprivate weak var textView: UITextView!
    
    /// This UILabel shall serve as the placeholder view for the UITextView.
    @IBOutlet fileprivate weak var placeholderView: UILabel!
    
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
    
    /// Presenter for PlaceholderTextView
    fileprivate class Presenter: BaseViewPresenter {
        
        /// Additional text change listener that can be chained to the main
        /// text change listener. Default to Observable.empty().
        fileprivate var textChangeListeners: [AnyObserver<String?>]
        
        /// Dispose of subscribed Observables when deinit() is called.
        fileprivate let disposeBag: DisposeBag
        
        /// Set this to true once all subviews have been laid out.
        fileprivate lazy var initialized = false
        
        fileprivate init(view: PlaceholderTextView) {
            disposeBag = DisposeBag()
            textChangeListeners = []
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
                let view = view as? PlaceholderTextView,
                let textView = view.textView,
                let placeholderView = view.placeholderView
            else {
                return
            }
            
            defer { initialized = true }
            
            let accessory = CompletionAccessory.builder()
                .with(target: self)
                .with(selectorType: self)
                .with(confirmId: "confirm")
                .with(cancelId: "cancel")
                .build()
            
            textView.addAccessory(accessory)
            
            // Listen to text change events.
            textView.rx.text
                .asObservable()
                .doOnNext(textDidChange)
                .doOnError({self.textDidChange(to: $0.localizedDescription)})
                .flatMap({text in
                    Observable.concat(
                        self.rxTogglePlaceholder(whileCurrentTextIs: text),
                        Observable.concat(self.textChangeListeners)
                    )
                })
                .observeOn(MainScheduler.instance)
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

extension PlaceholderTextView: InputFieldType {
    /// Override super tintColor to return placeholderView's tintColor.
    override public var tintColor: UIColor! {
        get { return placeholderView?.tintColor }
        set { placeholderView?.tintColor = newValue }
    }
    
    /// Return the textView's textColor.
    public var textColor: UIColor? {
        get { return textView?.textColor }
        set { textView?.textColor = newValue }
    }
    
    /// Return the text as displayed by textView.
    public var text: String? {
        get { return textView?.text }
        set { textView?.text = newValue }
    }
    
    /// Return the text as dislayed by placeholderView. This text is used as
    /// the placeholder.
    public var placeholder: String? {
        get { return placeholderView?.text }
        set { placeholderView?.text = newValue }
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
}

fileprivate extension PlaceholderTextView.Presenter {
    
    /// Optionally cast viewDelegate to the current UIView subclass.
    var view: PlaceholderTextView? {
        return viewDelegate as? PlaceholderTextView
    }
}

public extension PlaceholderTextView {
    
    /// Add an Observable text listener.
    ///
    /// - Parameter listener: An Observable instance.
    public func addTextChangeListener(_ listener: AnyObserver<String?>) {
        presenter.textChangeListeners.append(listener)
    }
}

fileprivate extension PlaceholderTextView.Presenter {
    
    /// Toggle placeholder visibility, depending on the currently displayed
    /// text. For e.g., if the current text is nil or empty, toggle placeholder
    /// to be visible.
    ///
    /// - Parameter text: The currently displayed text.
    /// - Returns: An Observable instance.
    fileprivate func rxTogglePlaceholder(whileCurrentTextIs text: String?)
        -> Observable<String?>
    {
        guard let placeholderView = view?.placeholderView else {
            debugException()
            return Observable.just(text)
        }
        
        let source: Observable<Bool>
        
        if let text = text, text.isNotEmpty, placeholderView.alpha > 0 {
            source = placeholderView.rxToggleVisible(toBe: false)
        } else if text == nil || (text!.isEmpty && placeholderView.alpha < 1) {
            source = placeholderView.rxToggleVisible(toBe: true)
        } else {
            source = Observable.just(true)
        }
        
        return source.map({_ in text})
    }
    
    /// This method will be called when the textView's text is changed.
    ///
    /// - Parameter text: The new text as displayed by the textView.
    fileprivate func textDidChange(to text: String?) {}
}
