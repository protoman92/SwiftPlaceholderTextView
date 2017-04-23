//
//  UIplaceholderLabelTests.swift
//  SwiftPlaceholderTextView
//
//  Created by Hai Pham on 4/23/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import RxCocoa
import RxSwift
import RxTest
import SwiftUtilities
import SwiftUIUtilities
import SwiftUtilitiesTests
import XCTest

class UIplaceholderLabelTests: XCTestCase {
    var placeholderTextView: UIPlaceholderTextView!
    
    var textView: UITextView! {
        return placeholderTextView.textView
    }
    
    var placeholderLabel: UILabel! {
        return placeholderTextView.placeholderLabel
    }
    
    override func setUp() {
        super.setUp()
        placeholderTextView = UIPlaceholderTextView()
        placeholderTextView.awakeFromNib()
        placeholderTextView.layoutSubviews()
    }
    
    func test_subviews_shouldBeOfCorrectType() {
        // Setup
        
        // When
        
        // Then
        XCTAssertTrue(textView is BaseTextView)
        XCTAssertTrue(placeholderLabel is BaseLabel)
    }
    
    func test_dynamicFontType_shouldWorkCorrectly() {
        // Setup
        let fontName = String(describing: 1)
        let fontSize = String(describing: 2)
        let textView = self.textView as! BaseTextView
        let placeholderLabel = self.placeholderLabel as! BaseLabel
        
        // When
        placeholderTextView.fontName = fontName
        placeholderTextView.fontSize = fontSize
        
        // Then
        XCTAssertEqual(textView.fontName!, fontName)
        XCTAssertEqual(textView.fontSize!, fontSize)
        XCTAssertEqual(placeholderLabel.fontName!, fontName)
        XCTAssertEqual(placeholderLabel.fontSize!, fontSize)
    }
    
//    func test_textObservable_shouldWorkCorrectly() {
//        // Setup
//        let scheduler = TestScheduler(initialClock: 0)
//        let observer = scheduler.createObserver(String.self)
//        let disposeBag = DisposeBag()
//        let inputs = (0..<1).map(String.init)
//        
//        // When
//        placeholderTextView.rx.text
//            .asObservable()
//            .throttle(0.1, scheduler: MainScheduler.instance)
//            .logNext()
//            .map({$0 ?? ""})
//            .observeOn(MainScheduler.instance)
//            .subscribe(observer)
//            .addDisposableTo(disposeBag)
//        
//        inputs.forEach({input in
//            synchronized(textView) { textView.text = input }
//        })
//        
//        // Then
//        let events = observer.events
//        let nextEvents = events.flatMap({$0.value.element})
//        XCTAssertEqual(nextEvents, inputs)
//    }
}
