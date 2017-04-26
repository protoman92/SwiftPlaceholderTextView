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
    fileprivate let expectationTimeout: TimeInterval = 10
    
    fileprivate var placeholderTextView: UIPlaceholderTextView!
    
    fileprivate var textView: UITextView! {
        return placeholderTextView.textView
    }
    
    fileprivate var placeholderLabel: UILabel! {
        return placeholderTextView.placeholderLabel
    }
    
    override func setUp() {
        super.setUp()
        placeholderTextView = UIPlaceholderTextView()
        placeholderTextView.awakeFromNib()
        placeholderTextView.layoutSubviews()
    }
    
    fileprivate func createInputs() -> [String] {
        var inputs = [String]()
        
        for i in 0..<1000 {
            let text: String
            
            // We need to do this to avoid two repeating inputs, since
            // rx.text does not emit value if it receives the same String
            // input.
            if i > 0 && inputs[i - 1].isNotEmpty && Bool.random() {
                text = ""
            } else {
                text = "\(String.random(withLength: 5))-\(i)"
            }
            
            inputs.append(text)
        }
        
        return inputs
    }
    
    func test_subviews_shouldBeOfCorrectType() {
        // Setup
        
        // When
        
        // Then
        XCTAssertTrue(textView is UIBaseTextView)
        XCTAssertTrue(placeholderLabel is UIBaseLabel)
    }
    
    func test_dynamicFontType_shouldWorkCorrectly() {
        // Setup
        let fontName = String(describing: 1)
        let fontSize = String(describing: 2)
        let textView = self.textView as! UIBaseTextView
        let placeholderLabel = self.placeholderLabel as! UIBaseLabel
        
        // When
        placeholderTextView.fontName = fontName
        placeholderTextView.fontSize = fontSize
        
        // Then
        XCTAssertEqual(textView.fontName!, fontName)
        XCTAssertEqual(textView.fontSize!, fontSize)
        XCTAssertEqual(placeholderLabel.fontName!, fontName)
        XCTAssertEqual(placeholderLabel.fontSize!, fontSize)
    }
    
    func test_textObservable_shouldWorkCorrectly() {
        // Setup
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(String.self)
        let disposeBag = DisposeBag()
        let inputs = createInputs()
        var mutableInputs = inputs
        let expect = expectation(description: "Should have worked")
        
        // When
        placeholderTextView.rx.text
            .asObservable()
            .map({$0 ?? ""})
            .skip(1) // Skip 1 to skip empty string emission.
            .take(inputs.count)
            .logNext()
            .doOnNext({_ in
                if mutableInputs.isNotEmpty {
                    self.textView.text = mutableInputs.removeFirst()
                }
            })
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        placeholderTextView.text = mutableInputs.removeFirst()
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        XCTAssertEqual(observer.nextElements(), inputs)
    }
    
    func test_textChange_shouldInfluencePlaceholder() {
        // Setup
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(String.self)
        let disposeBag = DisposeBag()
        let inputs = createInputs()
        var mutableInputs = inputs
        let expect = expectation(description: "Should have worked")
        
        // When
        placeholderTextView.rx.text
            .asObservable()
            .map({$0 ?? ""})
            .skip(1) // Skip 1 to skip empty string emission.
            .take(inputs.count)
            .doOnNext({
                // Then
                let alpha = self.placeholderLabel.alpha
                XCTAssertEqual(alpha, $0.isEmpty ? 1 : 0)
            })
            .doOnNext({_ in
                if mutableInputs.isNotEmpty {
                    self.textView.text = mutableInputs.removeFirst()
                }
            })
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        textView.text = mutableInputs.removeFirst()
        waitForExpectations(timeout: expectationTimeout, handler: nil)
    }
}
