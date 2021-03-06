//
//  LinkLabel.swift
//  LinkLabel
//
//  Created by Asakura Shinsuke on 2017/09/13.
//  Copyright © 2017年 Asakura Shinsuke. All rights reserved.
//

import UIKit

public protocol LNKLabelDelegate: NSObjectProtocol {
    func didTaped(label: LNKLabel, pattern: Pattern, matchText: String, range: NSRange)
} 

public class LNKLabel: UILabel {
    
    fileprivate var matcher = Matcher()
    public var delegate: LNKLabelDelegate?
    
    override public var text: String? {
        didSet { self.attributedText = attributedString() }
    }
    public var linkPatterns: [Pattern]? {
        didSet { self.attributedText = attributedString() }
    }
    
    
    private func attributedString() -> NSAttributedString? {
        guard let text = text, let linkPatterns = linkPatterns else { return nil }
        matcher.text = text
        matcher.patterms = linkPatterns
        var attribute = NSMutableAttributedString(string: text)
        for match in matcher.matches {
            for link in match.value {
                addAttribute(attribute: &attribute, plainText: text, targetText: link.0, range: link.1)
            }
        }
        return attribute
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        self.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(LNKLabel.didTaped(gesture:)))
        gesture.numberOfTapsRequired = 1
        self.addGestureRecognizer(gesture)
    }
    
    @objc private func didTaped(gesture: UIGestureRecognizer) {
        guard let text = text else { return }
        let touchPoint = gesture.location(in: self)
        for match in matcher.matches {
            for link in match.value {
                let glyphRect = rect(of: link.0, in: text, range: link.1)
                if glyphRect == .zero {
                    continue
                }
                if glyphRect.contains(touchPoint) {
                    self.didTaped(link: link, pattern: match.key)
                    break
                }
            }
        }
    }
    
    private func addAttribute(attribute: inout NSMutableAttributedString, plainText: String, targetText: String, range: NSRange) {
        attribute.addAttributes([NSAttributedStringKey.font : self.font], range: NSMakeRange(0, plainText.count))
        attribute.addAttributes([NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue,
                                 NSAttributedStringKey.underlineColor : UIColor.blue,
                                 NSAttributedStringKey.foregroundColor : UIColor.blue], range: range)
    }
    
    private func rect(of text: String, in plainText: String, range: NSRange) -> CGRect {

        guard let attributedText = self.attributedText else { return .zero }
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: self.frame.size)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        let toRange = range
        let glyphRange = layoutManager.glyphRange(forCharacterRange: toRange, actualCharacterRange: nil)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        return glyphRect
    }
    
    private func didTaped(link: (String, NSRange), pattern: Pattern) {
        guard let delegate = delegate else { return }
        delegate.didTaped(label: self, pattern: pattern, matchText: link.0, range: link.1)
    }
}

