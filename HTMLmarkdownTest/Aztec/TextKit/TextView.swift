//
//  TextView.swift
//  HTMLmarkdownTest
//
//  Created by Natalia Sinitsyna on 28.12.2022.
//

import UIKit
import Foundation
import CoreServices

// MARK: - TextViewAttachmentDelegate
//
public protocol TextViewAttachmentDelegate: AnyObject {

    /// This method requests from the delegate the image at the specified URL.
    ///
    /// - Parameters:
    ///     - textView: the `TextView` the call has been made from.
    ///     - attachment: the attachment that is requesting the image
    ///     - imageURL: the url to download the image from.
    ///     - success: when the image is obtained, this closure should be executed.
    ///     - failure: if the image cannot be obtained, this closure should be executed.
    ///
    func textView(_ textView: TextView,
                  attachment: NSTextAttachment,
                  imageAt url: URL,
                  onSuccess success: @escaping (UIImage) -> Void,
                  onFailure failure: @escaping () -> Void)

    /// Called when an attachment doesn't have an available source URL to provide an image representation.
    ///
    /// - Parameters:
    ///   - textView: the textview that is requesting the image
    ///   - attachment: the attachment that does not an have image source
    ///
    /// - Returns: an UIImage to represent the attachment graphically
    ///
    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage

    /// Called after an attachment is selected with a single tap.
    ///
    /// - Parameters:
    ///   - textView: the textview where the attachment is.
    ///   - attachment: the attachment that was selected.
    ///   - position: touch position relative to the textview.
    ///
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint)

    /// Called after an attachment is deselected with a single tap.
    ///
    /// - Parameters:
    ///   - textView: the textview where the attachment is.
    ///   - attachment: the attachment that was deselected.
    ///   - position: touch position relative to the textView
    ///
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint)
}

// MARK: - TextViewFormattingDelegate
//
public protocol TextViewFormattingDelegate: AnyObject {

    /// Called a text view command toggled a style.
    ///
    /// If you have a format bar, you should probably update it here.
    ///
    func textViewCommandToggledAStyle()
}

// MARK: - TextViewPasteboardDelegate
//
public protocol TextViewPasteboardDelegate: AnyObject {

    /// Called by the TextView when it's attempting to paste the contents of the pasteboard.
    ///
    /// - Returns: True if the paste succeeded, false if it did not.
    func tryPasting(in textView: TextView) -> Bool

    /// Called by the TextView when it's attempting to paste HTML content.
    ///
    /// - Returns: True if the paste succeeded, false if it did not.
    func tryPastingHTML(in textView: TextView) -> Bool

    /// Called by the TextView when it's attempting to paste an attributed string.
    ///
    /// - Returns: True if the paste succeeded, false if it did not.
    func tryPastingAttributedString(in textView: TextView) -> Bool

    /// Called by the TextView when it's attempting to paste a string.
    ///
    /// - Returns: True if the paste succeeded, false if it did not.
    func tryPastingString(in textView: TextView) -> Bool
}

// MARK: - TextView
//
open class TextView: UITextView {

    // MARK: - Aztec Delegates

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    open weak var textAttachmentDelegate: TextViewAttachmentDelegate?

    /// Formatting Delegate: to be used by the Edition's Format Bar.
    ///
    open weak var formattingDelegate: TextViewFormattingDelegate?

    /// If this is true the text view will notify is delegate and notification system when changes happen by calls to methods like setHTML
    ///
    open var shouldNotifyOfNonUserChanges = true

    /// If this is true the typing attributes will be recalculated when deleting backward
    ///
    open var shouldRecalculateTypingAttributesOnDeleteBackward = true

    // MARK: - Customizable Input VC
    
    private var customInputViewController: UIInputViewController?
    
    open override var inputViewController: UIInputViewController? {
        get {
            return customInputViewController
        }
        
        set {
            customInputViewController = newValue
        }
    }
    
    // MARK: - Behavior configuration
    
    private static let singleLineParagraphFormatters: [AttributeFormatter] = [
        HeaderFormatter(headerLevel: .h1),
        HeaderFormatter(headerLevel: .h2),
        HeaderFormatter(headerLevel: .h3),
        HeaderFormatter(headerLevel: .h4),
        HeaderFormatter(headerLevel: .h5),
        HeaderFormatter(headerLevel: .h6),
        FigureFormatter(),
        FigcaptionFormatter(),
    ]
    
    /// At some point moving ahead, this could be dynamically generated from the full list of registered formatters
    ///
    private lazy var paragraphFormatters: [ParagraphAttributeFormatter] = [
        BlockquoteFormatter(),
        HeaderFormatter(headerLevel:.h1),
        HeaderFormatter(headerLevel:.h2),
        HeaderFormatter(headerLevel:.h3),
        HeaderFormatter(headerLevel:.h4),
        HeaderFormatter(headerLevel:.h5),
        HeaderFormatter(headerLevel:.h6),
        PreFormatter(placeholderAttributes: self.defaultAttributes),
        TextListFormatter(style: .ordered),
        TextListFormatter(style: .unordered),
    ]

    // MARK: - Properties: Text Lists

    var maximumListIndentationLevels = 7
    
    // MARK: - Properties: Blockquotes
    
    /// The max levels of quote indentation allowed
    /// Default is 9
    public var maximumBlockquoteIndentationLevels = 9

    // MARK: - Properties: UI Defaults

    /// The font to use to render any HTML that doesn't specify an explicit font.
    /// If this is changed all the instances that use this font will be updated to the new one.
    public var defaultFont: UIFont {
        didSet {
            textStorage.replace(font: oldValue, with: defaultFont)
        }
    }

    public let defaultParagraphStyle: ParagraphStyle
    var defaultMissingImage: UIImage
    
    fileprivate var defaultAttributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .paragraphStyle: defaultParagraphStyle,
        ]
        if let color = defaultTextColor {
            attributes[.foregroundColor] = color
        }
        return attributes
    }

    open lazy var defaultTextColor: UIColor? = {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return UIColor.darkText
        }
    }()

    open override var textColor: UIColor? {
        set {
            super.textColor = newValue
            defaultTextColor = newValue
        }

        get {
            return super.textColor
        }
    }

    // MARK: - Plugin Loading
    
    var pluginManager: PluginManager {
        get {
            return storage.pluginManager
        }
    }
    
    public func load(_ plugin: Plugin) {
        pluginManager.load(plugin, in: self)
    }

    // MARK: - TextKit Aztec Subclasses

    public var storage: TextStorage {
        return textStorage as! TextStorage
    }

    var layout: LayoutManager {
        return layoutManager as! LayoutManager
    }


    // MARK: - Apparance Properties

    
    /// Blockquote Blocks Border and Text Colors
    ///
    @objc dynamic public var blockquoteBorderColors: [UIColor] {
        get {
            return layout.blockquoteBorderColors
        }
        set {
            layout.blockquoteBorderColors = newValue
        }
    }
    
    /// Blockquote Blocks Background Color.
    ///
    @objc dynamic public var blockquoteBackgroundColor: UIColor? {
        get {
            return layout.blockquoteBackgroundColor
        }
        set {
            layout.blockquoteBackgroundColor = newValue
        }
    }

    /// Blockquote Blocks Background Width.
    ///
    @objc dynamic public var blockquoteBorderWidth: CGFloat {
        get {
            return layout.blockquoteBorderWidth
        }
        set {
            layout.blockquoteBorderWidth = newValue
        }
    }

    /// Pre Blocks Background Color.
    ///
    @objc dynamic public var preBackgroundColor: UIColor? {
        get {
            return layout.preBackgroundColor
        }
        set {
            layout.preBackgroundColor = newValue
        }
    }


    // MARK: - Overwritten Properties
    
    /// The reason why we need to use this, instead of `super.typingAttributes`, is that iOS seems to sometimes
    /// modify `super.typingAttributes` without us having any mechanism to intercept those changes.
    ///
    private var myTypingAttributes = [NSAttributedString.Key: Any]()
    
    override open var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            return myTypingAttributes
        }
        
        set {
            // We're still setting the parent's typing attributes in case they're used directly
            // by any iOS feature.
            super.typingAttributes = newValue
            myTypingAttributes = newValue
        }
    }

    override open var textAlignment: NSTextAlignment {
        didSet {
            if (textAlignment != oldValue) {
                recalculateTypingAttributes()
            }
        }
    }


    /// This property returns the Attributes associated to the Extra Line Fragment.
    ///
    public var extraLineFragmentTypingAttributes: [NSAttributedString.Key: Any] {
        guard selectedTextRange?.start != endOfDocument else {
            return typingAttributes
        }

        let string = textStorage.string
        
        guard !string.isEndOfParagraph(before: string.endIndex) else {
            return defaultAttributes
        }
        
        let lastLocation = max(string.count - 1, 0)
        
        return textStorage.attributes(at: lastLocation, effectiveRange: nil)
    }


    // MARK: - Init & deinit

    /// Creates a Text View using the provided parameters as a base for HTML rendering.
    /// - Parameter defaultFont: The font to use to render the elements if no specific font is set by the HTML.
    /// - Parameter defaultParagraphStyle: The default paragraph style if no explicit attributes are defined in HTML
    /// - Parameter defaultMissingImage: The image to use if the view is not able to render an image specified in the HTML.
    @objc public init(
        defaultFont: UIFont,
        defaultParagraphStyle: ParagraphStyle = ParagraphStyle.default,
        defaultMissingImage: UIImage) {

        self.defaultFont = UIFontMetrics.default.scaledFont(for: defaultFont)
        
        self.defaultParagraphStyle = defaultParagraphStyle
        self.defaultMissingImage = defaultMissingImage

        let storage = TextStorage()
        let layoutManager = LayoutManager()
        let container = NSTextContainer()

        container.widthTracksTextView = true
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        super.init(frame: CGRect(x: 0, y: 0, width: 10, height: 10), textContainer: container)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        defaultFont = FontProvider.shared.defaultFont
        defaultParagraphStyle = ParagraphStyle.default
        defaultMissingImage = Assets.imageIcon
        
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        allowsEditingTextAttributes = true
        adjustsFontForContentSizeCategory = true

        font = defaultFont
        linkTextAttributes = [.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue), .foregroundColor: tintColor as Any]
        typingAttributes = defaultAttributes
        setupLayoutManager()
    }

    private func setupLayoutManager() {
        guard let aztecLayoutManager = layoutManager as? LayoutManager else {
            return
        }

        aztecLayoutManager.extraLineFragmentTypingAttributes = { [weak self] in
            return self?.extraLineFragmentTypingAttributes ?? [:]
        }
    }

    // MARK: - Intercept copy paste operations

    open override func cut(_ sender: Any?) {
        let html = storage.getHTML(range: selectedRange)
        super.cut(sender)

        storeInPasteboard(html: html)
    }

    open override func copy(_ sender: Any?) {
        let html = storage.getHTML(range: selectedRange)
        super.copy(sender)

        storeInPasteboard(html: html)
    }
    
    // MARK: - Intercept Keystrokes

    public lazy var carriageReturnKeyCommand: UIKeyCommand = {
        return UIKeyCommand(input: String(.carriageReturn), modifierFlags: .shift, action: #selector(handleShiftEnter(command:)))
    }()

    public lazy var tabKeyCommand: UIKeyCommand = {
        return UIKeyCommand(input: String(.tab), modifierFlags: [], action: #selector(handleTab(command:)))
    }()

    public lazy var shiftTabKeyCommand: UIKeyCommand = {
        return  UIKeyCommand(input: String(.tab), modifierFlags: .shift, action: #selector(handleShiftTab(command:)))
    }()

    override open var keyCommands: [UIKeyCommand]? {
        get {
            // When the keyboard "enter" key is pressed, the keycode corresponds to .carriageReturn,
            // even if it's later converted to .lineFeed by default.
            //
            return [
                carriageReturnKeyCommand,
                shiftTabKeyCommand,
                tabKeyCommand,
            ]
        }
    }

    @objc func handleShiftEnter(command: UIKeyCommand) {
        insertText(String(.lineSeparator))
    }

    @objc func handleShiftTab(command: UIKeyCommand) {
        decreaseIndent()
    }

    @objc func handleTab(command: UIKeyCommand) {
        increaseIndent()
    }

    // MARK: - General Indentation

    /// Increases the indentation of the selected range
    open func increaseIndent() {
        let lists = TextListFormatter.lists(in: typingAttributes)
        let quotes = BlockquoteFormatter.blockquotes(in: typingAttributes)

        if let list = lists.last, lists.count < maximumListIndentationLevels {
            indent(list: list)
        } else if let quote = quotes.last, quotes.count < maximumBlockquoteIndentationLevels {
            indent(blockquote: quote)
        } else {
            insertText(String(.tab))
        }
    }
    
    /// Decreases the indentation of the selected range
    open func decreaseIndent() {
        let lists = TextListFormatter.lists(in: typingAttributes)
        let quotes = BlockquoteFormatter.blockquotes(in: typingAttributes)

        if let list = lists.last {
            indent(list: list, increase: false)
        } else if let quote = quotes.last {
            indent(blockquote: quote, increase: false)
        }
    }

    // MARK: - Text List indent methods
    
    private func indent(list: TextList, increase: Bool = true) {
        let formatter = TextListFormatter(style: list.style, placeholderAttributes: nil, increaseDepth: true)
        let li = LiFormatter(placeholderAttributes: nil)

        let targetRange = formatter.applicationRange(for: selectedRange, in: storage)

        performUndoable(at: targetRange) {
            let finalRange: NSRange
            if increase {
                finalRange = increaseIndent(listFormatter: formatter, liFormatter: li, targetRange: targetRange)
            } else {
                finalRange = decreaseIndent(listFormatter: formatter, liFormatter: li, targetRange: targetRange)
            }
            typingAttributes = textStorage.attributes(at: targetRange.location, effectiveRange: nil)
            return finalRange
        }

    }
    
    // MARK: Text List increase or decrease indentation
    private func increaseIndent(listFormatter: TextListFormatter, liFormatter: LiFormatter, targetRange: NSRange) -> NSRange {
        let finalRange = listFormatter.applyAttributes(to: storage, at: targetRange)
        liFormatter.applyAttributes(to: storage, at: targetRange)
        
        return finalRange
    }
    
    private func decreaseIndent(listFormatter: TextListFormatter, liFormatter: LiFormatter, targetRange: NSRange) -> NSRange {
        let finalRange = listFormatter.removeAttributes(from: storage, at: targetRange)
        liFormatter.removeAttributes(from: storage, at: targetRange)
        
        return finalRange
    }
    
    
    // MARK: - Blockquote indent methods
    
    private func indent(blockquote: Blockquote, increase: Bool = true) {
        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes, increaseDepth: true)
        let targetRange = formatter.applicationRange(for: selectedRange, in: storage)

        performUndoable(at: targetRange) {
            let finalRange: NSRange
            if increase {
                finalRange = increaseIndent(quoteFormatter: formatter, targetRange: targetRange)
            } else {
                finalRange = decreaseIndent(quoteFormatter: formatter, targetRange: targetRange)
            }
            typingAttributes = textStorage.attributes(at: targetRange.location, effectiveRange: nil)
            return finalRange
        }

    }

    // MARK: Blockquote increase or decrease indentation
    private func increaseIndent(quoteFormatter: BlockquoteFormatter, targetRange: NSRange) -> NSRange {
        let finalRange = quoteFormatter.applyAttributes(to: storage, at: targetRange)
        return finalRange
    }
    
    private func decreaseIndent(quoteFormatter: BlockquoteFormatter, targetRange: NSRange) -> NSRange {
        let finalRange = quoteFormatter.removeAttributes(from: storage, at: targetRange)
        return finalRange
    }
    

    // MARK: - Pasteboard Helpers

    internal func storeInPasteboard(encoded data: Data, pasteboard: UIPasteboard = UIPasteboard.general) {
        if pasteboard.numberOfItems > 0 {
            pasteboard.items[0][NSAttributedString.pastesboardUTI] = data;
        } else {
            pasteboard.addItems([[NSAttributedString.pastesboardUTI: data]])
        }
    }

    internal func storeInPasteboard(html: String, pasteboard: UIPasteboard = UIPasteboard.general) {
        if pasteboard.numberOfItems > 0 {
            pasteboard.items[0][kUTTypeHTML as String] = html;
        } else {
            pasteboard.addItems([[kUTTypeHTML as String: html]])
        }
    }

    // MARK: - Intercept keyboard operations

//    open override func insertText(_ text: String) {
//
//        // For some reason the text view is allowing the attachment style to be set in
//        // typingAttributes.  That's simply not acceptable.
//        //
//        // This was causing the following issue:
//        // https://github.com/wordpress-mobile/AztecEditor-iOS/issues/462
//        //
//        typingAttributes[.attachment] = nil
//
//        guard !ensureRemovalOfParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: text) else {
//            return
//        }
//
//        /// Whenever the user is at the end of the document, while editing a [List, Blockquote, Pre], we'll need
//        /// to insert a `\n` character, so that the Layout Manager immediately renders the List's new bullet
//        /// (or Blockquote's BG).
//        ///
//        ensureInsertionOfEndOfLine(beforeInserting: text)
//
//        // Emoji Fix:
//        // Fallback to the default font, whenever the Active Font's Family doesn't match with the Default Font's family.
//        // We do this twice (before and after inserting text), in order to properly handle two scenarios:
//        //
//        // - Before: Corrects the typing attributes in the scenario in which the user moves the cursor around.
//        //   Placing the caret after an emoji might update the typing attributes, and in some scenarios, the SDK might
//        //   fallback to Courier New.
//        //
//        // - After: If the user enters an Emoji, toggling Bold / Italics breaks. This is due to a glitch in the
//        //   SDK: the font "applied" after inserting an emoji breaks with our styling mechanism.
//        //
//        restoreDefaultFontIfNeeded()
//
//        ensureRemovalOfLinkTypingAttribute(at: selectedRange)
//
//        super.insertText(text)
//
//        evaluateRemovalOfSingleLineParagraphAttributesAfterSelectionChange()
//
//        restoreDefaultFontIfNeeded()
//
//        ensureCursorRedraw(afterEditing: text)
//    }

    open override func deleteBackward() {
        var deletionRange = selectedRange
        var deletedString = NSAttributedString()
        if deletionRange.length == 0 {
            deletionRange.location = max(selectedRange.location - 1, 0)
            deletionRange.length = 1
        }
        if storage.length > 0 {
            deletedString = storage.attributedSubstring(from: deletionRange)
        }
        
        ensureRemovalOfParagraphStylesBeforeRemovingCharacter(at: selectedRange)

        super.deleteBackward()

        evaluateRemovalOfSingleLineParagraphAttributesAfterSelectionChange()
        ensureRemovalOfParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument()
        ensureCursorRedraw(afterEditing: deletedString.string)
        if shouldRecalculateTypingAttributesOnDeleteBackward {
            recalculateTypingAttributes()
        }
        notifyTextViewDidChange()
    }

    // MARK: - UIView Overrides

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        layoutIfNeeded()
    }

    // MARK: - UITextView Overrides
    
    open override func caretRect(for position: UITextPosition) -> CGRect {
        var caretRect = super.caretRect(for: position)
        let characterIndex = offset(from: beginningOfDocument, to: position)
        
        guard layoutManager.isValidGlyphIndex(characterIndex) else {
            return caretRect
        }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        let usedLineFragment = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        guard !usedLineFragment.isEmpty else {
            return caretRect
        }
     
        caretRect.origin.y = usedLineFragment.origin.y + textContainerInset.top
        caretRect.size.height = usedLineFragment.size.height

        return caretRect
    }

    // MARK: - HTML Interaction

    /// Converts the current Attributed Text into a raw HTML String
    ///
    /// - Returns: The HTML version of the current Attributed String.
    ///
    public func getHTML(prettify: Bool = true) -> String {
        return storage.getHTML(prettify: prettify)
    }
    
    /// Loads the specified HTML into the editor, and records a new undo step,
    /// making sure the undo stack isn't reset
    ///
    /// - Parameters:
    ///     - html: the HTML to load into the editor.
    ///
    public func setHTMLUndoable(_ html: String) {
        replace(storage.rangeOfEntireString, withHTML: html)
        recalculateTypingAttributes()
    }

    /// Loads the specified HTML into the editor.
    ///
    /// - Parameter html: The raw HTML we'd be editing.
    ///
    public func setHTML(_ html: String) {
        // NOTE: there's a bug in UIKit that causes the textView's font to be changed under certain
        //      conditions.  We are assigning the default font here again to avoid that issue.
        //
        //      More information about the bug here:
        //          https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/58
        //
        font = defaultFont

        storage.setHTML(html, defaultAttributes: defaultAttributes)
        recalculateTypingAttributes()

        notifyTextViewDidChange()
        formattingDelegate?.textViewCommandToggledAStyle()
    }
    
    public func replace(_ range: NSRange, withHTML html: String) {

        let string = storage.htmlConverter.attributedString(from: html, defaultAttributes: defaultAttributes)

        let originalString = storage.attributedSubstring(from: range)
        let finalRange = NSRange(location: range.location, length: string.length)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: finalRange)
        })

        storage.replaceCharacters(in: range, with: string)
        selectedRange = NSRange(location: finalRange.location + finalRange.length, length: 0)
    }

    // MARK: - Getting format identifiers

    private static let formatterMap: [FormattingIdentifier: AttributeFormatter] = [
        .bold: Configuration.defaultBoldFormatter,
        .italic: ItalicFormatter(),
        .underline: SpanUnderlineFormatter(),
        .strikethrough: StrikethroughFormatter(),
        .orderedlist: TextListFormatter(style: .ordered),
        .unorderedlist: TextListFormatter(style: .unordered),
        .blockquote: BlockquoteFormatter(),
        .header1: HeaderFormatter(headerLevel: .h1),
        .header2: HeaderFormatter(headerLevel: .h2),
        .header3: HeaderFormatter(headerLevel: .h3),
        .header4: HeaderFormatter(headerLevel: .h4),
        .header5: HeaderFormatter(headerLevel: .h5),
        .header6: HeaderFormatter(headerLevel: .h6),
        .p: HTMLParagraphFormatter(),
    ]

    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Parameter range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    open func formattingIdentifiersSpanningRange(_ range: NSRange) -> Set<FormattingIdentifier> {
        guard storage.length != 0 else {
            return formattingIdentifiersForTypingAttributes()
        }

        if range.length == 0 {
            return formattingIdentifiersAtIndex(range.location)
        }

        var identifiers = Set<FormattingIdentifier>()

        for (key, formatter) in type(of: self).formatterMap {
            if formatter.present(in: storage, at: range) {
                identifiers.insert(key)
            }
        }

        return identifiers
    }


    /// Get a list of format identifiers at a specific index as a String array.
    ///
    /// - Parameter range: The character index to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    open func formattingIdentifiersAtIndex(_ index: Int) -> Set<FormattingIdentifier> {
        guard storage.length != 0 else {
            return []
        }

        let index = adjustedIndex(index)
        var identifiers = Set<FormattingIdentifier>()

        for (key, formatter) in type(of: self).formatterMap {
            if formatter.present(in: storage, at: index) {
                identifiers.insert(key)
            }
        }

        return identifiers
    }


    /// Get a list of format identifiers of the Typing Attributes.
    ///
    /// - Returns: A list of Formatting Identifiers.
    ///
    open func formattingIdentifiersForTypingAttributes() -> Set<FormattingIdentifier> {
        let activeAttributes = typingAttributes
        var identifiers = Set<FormattingIdentifier>()

        for (key, formatter) in type(of: self).formatterMap where formatter.present(in: activeAttributes) {
            identifiers.insert(key)
        }

        return identifiers
    }

    // MARK: - UIResponderStandardEditActions

    open override func toggleBoldface(_ sender: Any?) {
        // We need to make sure our formatter is called.  We can't go ahead with the default
        // implementation.
        //
        toggleBold(range: selectedRange)

        formattingDelegate?.textViewCommandToggledAStyle()
    }

    open override func toggleItalics(_ sender: Any?) {
        // We need to make sure our formatter is called.  We can't go ahead with the default
        // implementation.
        //
        toggleItalic(range: selectedRange)

        formattingDelegate?.textViewCommandToggledAStyle()
    }

    open override func toggleUnderline(_ sender: Any?) {
        // We need to make sure our formatter is called.  We can't go ahead with the default
        // implementation.
        //
        toggleUnderline(range: selectedRange)

        formattingDelegate?.textViewCommandToggledAStyle()
    }

    // MARK: - Formatting

    func toggle(formatter: AttributeFormatter, atRange range: NSRange) {

        let applicationRange = formatter.applicationRange(for: range, in: textStorage)
        let originalString = storage.attributedSubstring(from: applicationRange)
        
        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: applicationRange)
        })

        storage.toggle(formatter: formatter, at: range)

        if applicationRange.length == 0 {
            typingAttributes = formatter.toggle(in: typingAttributes)
        } else {
            // NOTE: We are making sure that the selectedRange location is inside the string
            // The selected range can be out of the string when you are adding content to the end of the string.
            // In those cases we check the atributes of the previous caracter
            let location = max(0,min(selectedRange.location, textStorage.length-1))
            typingAttributes = textStorage.attributes(at: location, effectiveRange: nil)
        }
        notifyTextViewDidChange()
    }

    func apply(formatter: AttributeFormatter, atRange range: NSRange, remove: Bool) {

        let applicationRange = formatter.applicationRange(for: range, in: textStorage)
        let originalString = storage.attributedSubstring(from: applicationRange)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: applicationRange)
        })

        if remove {
            formatter.removeAttributes(from: storage, at: applicationRange)
        } else {
            formatter.applyAttributes(to: storage, at: applicationRange)
        }

        if applicationRange.length == 0 {
            typingAttributes = formatter.toggle(in: typingAttributes)
        } else {
            // NOTE: We are making sure that the selectedRange location is inside the string
            // The selected range can be out of the string when you are adding content to the end of the string.
            // In those cases we check the atributes of the previous caracter
            let location = max(0,min(selectedRange.location, textStorage.length-1))
            typingAttributes = textStorage.attributes(at: location, effectiveRange: nil)
        }
        notifyTextViewDidChange()
    }

    /// Adds or removes a bold style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleBold(range: NSRange) {
        let formatter = Configuration.defaultBoldFormatter
        toggle(formatter: formatter, atRange: range)
    }


    /// Adds or removes a italic style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleItalic(range: NSRange) {
        let formatter = ItalicFormatter()
        toggle(formatter: formatter, atRange: range)
    }


    /// Adds or removes a underline style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnderline(range: NSRange) {
        let formatter = SpanUnderlineFormatter()
        toggle(formatter: formatter, atRange: range)
    }


    /// Adds or removes a strikethrough style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleStrikethrough(range: NSRange) {
        let formatter = StrikethroughFormatter()
        toggle(formatter: formatter, atRange: range)
    }

    /// Adds or removes a Pre style from the specified range.
    /// Pre are applied to an entire paragrah regardless of the range.
    /// If the range spans multiple paragraphs, the style is applied to all
    /// affected paragraphs.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    open func togglePre(range: NSRange) {
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = PreFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a blockquote style from the specified range.
    /// Blockquotes are applied to an entire paragrah regardless of the range.
    /// If the range spans multiple paragraphs, the style is applied to all
    /// affected paragraphs.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    open func toggleBlockquote(range: NSRange) {
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes)
        
        toggle(formatter: formatter, atRange: range)
        
        let citeFormatter = CiteFormatter()
        
        if citeFormatter.present(in: storage, at: selectedRange.location) {
            let applicationRange = citeFormatter.applicationRange(for: selectedRange, in: attributedText)
            
            performUndoable(at: applicationRange) {
                citeFormatter.removeAttributes(from: storage, at: applicationRange)
            }
        }

        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleOrderedList(range: NSRange) {
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = TextListFormatter(style: .ordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        let liFormatter = LiFormatter(placeholderAttributes: typingAttributes)
        let isOlTagPresent = formatter.present(in: storage, at: range)
        let isLiTagPresent = liFormatter.present(in: storage, at: range)

        if isOlTagPresent != isLiTagPresent {
            toggle(formatter: liFormatter, atRange: range)
        }
        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnorderedList(range: NSRange) {
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = TextListFormatter(style: .unordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        let liFormatter = LiFormatter(placeholderAttributes: typingAttributes)
        let isOlTagPresent = formatter.present(in: storage, at: range)
        let isLiTagPresent = liFormatter.present(in: storage, at: range)

        if isOlTagPresent != isLiTagPresent {
            toggle(formatter: liFormatter, atRange: range)
        }
        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleHeader(_ headerType: Header.HeaderType, range: NSRange) {
        let formatter = HeaderFormatter(headerLevel: headerType)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a mark style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleMark(range: NSRange) {
        let formatter = MarkFormatter()
        formatter.placeholderAttributes = self.defaultAttributes
        toggle(formatter: formatter, atRange: range)
    }

    /// Replaces with an horizontal ruler on the specified range
    ///
    /// - Parameter range: the range where the ruler will be inserted
    ///
    open func replaceWithHorizontalRuler(at range: NSRange) {
        let line = LineAttachment()
        replace(at: range, with: line)
    }

    /// Verifies if the Active Font's Family Name matches with our Default Font, or not. If the family diverges,
    /// this helper will proceed to restore the defaultFont's Typing Attributes
    /// This is meant as a workaround for the "Emojis Mixing Up Font's" glitch.
    ///
    private func restoreDefaultFontIfNeeded() {
        guard let activeFont = typingAttributes[.font] as? UIFont, activeFont.isAppleEmojiFont else {
            return
        }

        typingAttributes[.font] = defaultFont.withSize(activeFont.pointSize)
    }


    /// Inserts an end-of-line character whenever the provided range is at end-of-file, in an
    /// empty paragraph. This is useful when attempting to apply a paragraph-level style at EOF,
    /// since it won't be possible without the paragraph having any characters.
    ///
    /// Call this method before applying the formatter.
    ///
    /// - Parameters:
    ///     - range: the range where the formatter will be applied.
    ///
    private func ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange range: NSRange) {

        let selectedRangeForSwift = textStorage.string.nsRange(fromUTF16NSRange: range)

        if selectedRangeForSwift.location == textStorage.length
            && textStorage.string.isEmptyLine(at: selectedRangeForSwift.location) {

            insertEndOfLineCharacter()
        }
    }

    /// Inserts an end-of-line chracter whenever:
    ///
    ///     A.  We're about to insert a new line
    ///     B.  We're at the end of the document
    ///     C.  There's a List (OR) Blockquote (OR) Pre active
    ///
    /// We're doing this as a workaround, in order to force the LayoutManager render the Bullet (OR)
    /// Blockquote's background.
    ///
    private func ensureInsertionOfEndOfLine(beforeInserting text: String) {

        guard text.isEndOfLine(),
            selectedRange.location == storage.length else {
                return
        }

        let formatters: [AttributeFormatter] = [
            BlockquoteFormatter(),
            PreFormatter(placeholderAttributes: self.defaultAttributes),
            TextListFormatter(style: .ordered),
            TextListFormatter(style: .unordered)
        ]

        let activeTypingAttributes = typingAttributes
        let found = formatters.first { formatter in
            return formatter.present(in: activeTypingAttributes)
        }

        guard found != nil else {
            return
        }

        insertEndOfLineCharacter()
    }

    /// Inserts a end-of-line character at the current position, while retaining the selectedRange
    /// and typingAttributes.
    ///
    private func insertEndOfLineCharacter() {
        let previousRange = selectedRange
        let previousStyle = convertFromNSAttributedStringKeyDictionary(typingAttributes)

        super.insertText(String(.paragraphSeparator))

        selectedRange = previousRange
        typingAttributes = convertToNSAttributedStringKeyDictionary(previousStyle)
    }

    /// Force the SDK to Redraw the cursor, asynchronously, if the edited text (inserted / deleted) requires it.
    /// This method was meant as a workaround for Issue #144.
    ///
    func ensureCursorRedraw(afterEditing text: String) {
        guard text == String(.lineFeed) else {
            return
        }

        forceRedrawCursorAfterDelay()
    }


    /// Force the SDK to Redraw the cursor, asynchronously, after a delay. This method was meant as a workaround
    /// for Issue #144: the Caret might end up redrawn below the Blockquote's custom background.
    ///
    /// Workaround: By changing the selectedRange back and forth, we're forcing UITextView to effectively re-render
    /// the caret.
    ///
    func forceRedrawCursorAfterDelay() {
        let delay = 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let pristine = self.selectedRange
            let maxLength = self.storage.length

            // Determine the Temporary Shift Location:
            // - If we're at the end of the document, we'll move the caret minus one character
            // - Otherwise, we'll move the caret plus one position
            //
            let delta = pristine.location == maxLength ? -1 : 1
            let location = min(max(pristine.location + delta, 0), maxLength)

            // Shift the SelectedRange to a nearby position: *FORCE* cursor redraw
            //
            self.selectedRange = NSMakeRange(location, 0)

            // Finally, restore the original SelectedRange and the typingAttributes we had before beginning
            //
            self.selectedRange = pristine
        }
    }
    
    // MARK: - UITextView workarounds
    
    /// When the selected text range is set, by default, any custom attributes are removed from typingAttributes.
    /// We override this property to fix that behavior.
    ///
    open override var selectedTextRange: UITextRange? {
        get {
            return super.selectedTextRange
        }
        
        set {
            if let start = newValue?.start {
                // We need to calculate the new typing attributes before we change the selected text range.
                // This is because as soon as we change the selected text range bellow, a call to
                // `textViewDidChangeSelection(_:)` will be triggered and we want the typing attributes to
                // be updated by then.
                let position = self.offset(from: self.beginningOfDocument, to: start)
                recalculateTypingAttributes(at: position)
            }
            super.selectedTextRange = newValue
        }
    }
    
    /// Convenience method to recalculate the typing attributes for the current `selectedRange`.
    ///
    private func recalculateTypingAttributes() {
        let location = selectedRange.location
        
        recalculateTypingAttributes(at: location)
    }
    
    /// Recalculate the typing attributes as if the caret was at the provided location.  This method is useful
    /// when the caret is about to be moved to the specified location, but we want the `typingAttributes` to be
    /// recalculated before the text view's `textViewDidChangeSelection(_:)` is called.
    ///
    /// Only call this method when sure that the typingAttributes need to be recalculated.  Keep in mind that
    /// recalculating the typingAttributes in the wrong moment can cause trouble (for example reverting a decision
    /// by the user to turn a style off).
    ///
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/1140
    ///
    /// - Parameters:
    ///     - location: the new caret location.
    ///
    private func recalculateTypingAttributes(at location: Int) {
        
        guard storage.length > 0 else {
            typingAttributes = defaultAttributes
            return
        }
        
        if storage.string.isEmptyLineAtEndOfFile(at: location) {
            removeParagraphPropertiesFromTypingAttributes()
        } else {
            let location = min(location, storage.length - 1)
            
            typingAttributes = attributedText.attributes(at: location, effectiveRange: nil)
        }
    }

    // MARK: - Embeds

    func replace(at range: NSRange, with attachment: NSTextAttachment) {
        let originalText = textStorage.attributedSubstring(from: range)
        let finalRange = NSRange(location: range.location, length: NSAttributedString.lengthOfTextAttachment)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        let attachmentString = NSAttributedString(attachment: attachment, attributes: typingAttributes)
        storage.replaceCharacters(in: range, with: attachmentString)
        selectedRange = NSMakeRange(range.location + NSAttributedString.lengthOfTextAttachment, 0)
        notifyTextViewDidChange()
    }

    /// Returns the associated NSTextAttachment, at a given point, if any.
    ///
    /// - Parameter point: The point on screen to check for attachments.
    ///
    /// - Returns: The associated NSTextAttachment.
    ///
    open func attachmentAtPoint(_ point: CGPoint) -> NSTextAttachment? {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return nil
        }

        var effectiveRange = NSRange()
        guard let attachment = textStorage.attribute(.attachment, at: index, effectiveRange: &effectiveRange) as? NSTextAttachment else {
            return nil
        }

        var bounds = layoutManager.boundingRect(forGlyphRange: effectiveRange, in: textContainer)
        bounds.origin.x += textContainerInset.left
        bounds.origin.y += textContainerInset.top

        return bounds.contains(point) ? attachment : nil
    }

    /// Move the selected range to the nearest character of the point specified in the textView
    ///
    /// - Parameter point: the position to move the selection to.
    ///
    open func moveSelectionToPoint(_ point: CGPoint) {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return
        }

        guard let locationAfter = textStorage.string.location(after: index) else {
            selectedRange = NSRange(location: index, length: 0)
            return;
        }
        var newLocation = locationAfter
        selectedRange = NSRange(location: newLocation, length: 0)
    }

    // MARK: - Captions

    open func caption(for attachment: NSTextAttachment) -> NSAttributedString? {
        return textStorage.caption(for: attachment)
    }
    
    open func removeCaption(for attachment: NSTextAttachment) {
        guard let attachmentRange = textStorage.ranges(forAttachment: attachment).first,
            let captionRange = textStorage.captionRange(for: attachment) else {
                return
        }
        
        let finalRange = NSRange(location: attachmentRange.location, length: attachmentRange.length + captionRange.length)
        
        textStorage.replaceCharacters(in: finalRange, with: NSAttributedString(attachment: attachment))
        
        notifyTextViewDidChange()
    }
    
    open func replaceCaption(for attachment: NSTextAttachment, with newCaption: NSAttributedString) {
        guard let attachmentRange = textStorage.ranges(forAttachment: attachment).first else {
            return
        }
        
        guard let existingCaptionRange = textStorage.captionRange(for: attachment) else {
            let newAttachmentString = NSAttributedString(attachment: attachment, caption: newCaption, attributes: [:])
            textStorage.replaceCharacters(in: attachmentRange, with: newAttachmentString)

            return
        }

        // We maintain the original paragraph style since this is really not intended to be editable.  It also maintains
        // the original Figure and Figcaption objects.
        let originalParagraphStyle = textStorage.attribute(.paragraphStyle, at: existingCaptionRange.location, effectiveRange: nil) as! ParagraphStyle
        var newAttributes = newCaption.attributes(at: 0, effectiveRange: nil)
        newAttributes[.paragraphStyle] = originalParagraphStyle
        
        // TODO: when the caption is not there, we must insert it (and format the attachment as a FIGURE())
        
        let finalCaption = NSMutableAttributedString()
        
        finalCaption.append(newCaption)
        finalCaption.append(NSAttributedString(.paragraphSeparator, attributes: [:]))
        finalCaption.setAttributes(newAttributes, range: finalCaption.rangeOfEntireString)
        
        textStorage.replaceCharacters(in: existingCaptionRange, with: finalCaption)
        
        notifyTextViewDidChange()
    }
 
    // MARK: - Storage Indexes (WTF?)


    /// The maximum index should never exceed the length of the text storage minus one,
    /// else we court out of index exceptions.
    ///
    /// - Parameter index: The candidate index. If the index is greater than the max allowed, the max is returned.
    ///
    /// - Returns: If the index is greater than the max allowed, the max is returned, else the original value.
    ///
    func maxIndex(_ index: Int) -> Int {
        if index >= storage.length {
            return max(storage.length - 1, 0)
        }

        return index
    }

    /// In most instances, the value of NSRange.location is off by one when compared to a character index.
    /// Call this method to get an adjusted character index from an NSRange.location.
    ///
    /// - Parameter index: The candidate index.
    ///
    /// - Returns: The specified or maximum index.
    ///
    func adjustedIndex(_ index: Int) -> Int {
        let index = maxIndex(index)
        return max(0, index - 1)
    }


    // MARK: - Attachments

    /// Invalidates the layout of the attachment and marks it to be refresh on the next update cycle.
    /// This method should be called after editing any kind of *Attachment, since, whenever its bounds
    /// do change, we'll need to perform a layout pass. Otherwise, TextKit's inner map won't match with
    /// what's actually onscreen.
    ///
    /// - Parameters:
    ///   - attachment: the attachment to update
    ///   - overlayUpdateOnly: when this arguments is true, the attachment is only marked to refresh it's display, witthout the need to relayout. This should only be used when changes done to the attachment don't affect it's previous dimensions.
    ///
    open func refresh(_ attachment: NSTextAttachment, overlayUpdateOnly: Bool = false) {
        guard let range = storage.range(for: attachment) else {
            return
        }
        if overlayUpdateOnly {
            layoutManager.invalidateDisplay(forCharacterRange: range)
        } else {
            storage.edited(.editedAttributes, range: range, changeInLength: 0)
        }
    }

    /// Helper that allows us to Edit a NSTextAttachment instance, with two extras:
    ///
    /// - Undo Support comes for free!
    /// - Layout will be ensured right after executing the edition block
    ///
    /// - Parameters:
    ///     - attachment: Instance to be edited
    ///     - block: Edition closure to be executed
    ///
    /// - Returns: a copy of the original attachment for undoing purposes.
    ///
    @discardableResult
    open func edit<T>(_ attachment: T, block: (T) -> ()) -> T where T:NSTextAttachment {

        precondition(storage.range(for: attachment) != nil)

        // Don't call this method if the attachment is not in the text view.
        let range = storage.range(for: attachment)!

        // This should NEVER fail because the copy should not change type.
        let copy = attachment.copy() as! T

        block(copy)

        performUndoable(at: range) {
            var originalAttributes = storage.attributes(at: range.location, effectiveRange: nil)
            originalAttributes[.attachment] = copy
            
            storage.setAttributes(originalAttributes, range: range)
            return range
        }
        
        notifyTextViewDidChange()
    
        return copy
    }


    // MARK: - More

    /// Replaces a range with a comment.
    ///
    /// - Parameters:
    ///     - range: The character range that must be replaced with a Comment Attachment.
    ///     - comment: The text for the comment.
    ///
    /// - Returns: the attachment object that can be used for further calls
    ///
    @discardableResult
    open func replace(_ range: NSRange, withComment comment: String) -> CommentAttachment {
        let attachment = CommentAttachment()
        attachment.text = comment
        replace(at: range, with: attachment)

        return attachment
    }
}

// MARK: - Single line attributes removal
//
private extension TextView {

    // MARK: - WORKAROUND: Removing paragraph styles after deleting the last character in the current line.

    /// Ensures Paragraph Styles are removed, if needed, *before* a character gets removed from the storage,
    /// at the specified range.
    ///
    /// - Parameter range: Range at which a character is about to be removed.
    ///
    func ensureRemovalOfParagraphStylesBeforeRemovingCharacter(at range: NSRange) {
        guard mustRemoveParagraphStylesBeforeRemovingCharacter(at: range) else {
            return
        }

        removeParagraphPropertiesFromTypingAttributes()
        removeParagraphProperties(from: range)
    }

    /// When deleting the newline between lines 1 and 2 in the following example:
    ///     Line 1: <empty>
    ///     Line 2: <empty> (with list style)
    ///     Line 3: <empty>
    ///
    /// Aztec tends to naturally maintain the list style alive, due to the newline between line 2 and
    /// 3, since line 1 has no paragraph style once its closing newline is removed (because it's empty).
    ///
    /// This method makes sure that in such a scenario (when line 1 is empty and we merge line 1 and 2),
    /// the paragraph styles from line 2 are removed too.
    ///
    /// - Parameter range: Range at which we'll remove a character
    ///
    /// - Returns: `true` if we should nuke the paragraph attributes.
    ///
    private func mustRemoveParagraphStylesBeforeRemovingCharacter(at range: NSRange) -> Bool {
        guard let previousParagraphRange = attributedText.paragraphRange(before: selectedRange)  else {
            return false
        }
        
        let currentParagraphRange = attributedText.paragraphRange(for: selectedRange)
        
        return previousParagraphRange != currentParagraphRange && storage.string.isEmptyParagraph(at: previousParagraphRange.location)
    }

    // MARK: - Single-line attributes logic.
    
    private func evaluateRemovalOfSingleLineParagraphAttributesAfterSelectionChange() {
        guard storage.string.isEmptyParagraph(at: selectedRange.location) else {
            return
        }
        
        removeSingleLineParagraphAttributes()
        removeBlockquoteAndCite()
    }

    /// Removes single-line paragraph attributes.
    ///
    private func removeSingleLineParagraphAttributes() {
        for formatter in type(of: self).singleLineParagraphFormatters {
            let range = formatter.applicationRange(for: selectedRange, in: textStorage)
            
            removeAttributes(managedBy: formatter, from: range)
            removeTypingAttributes(managedBy: formatter)
        }
    }
    
    /// Removes blockquote + cite after pressing ENTER in a line that has both styles.
    ///
    private func removeBlockquoteAndCite() {
        // Blockquote + cite removal
        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes)
        let citeFormatter = CiteFormatter()
        
        if formatter.present(in: typingAttributes)
            && citeFormatter.present(in: typingAttributes) {
            
            let applicationRange = formatter.applicationRange(for: selectedRange, in: storage)
            
            typingAttributes = formatter.remove(from: typingAttributes)
            typingAttributes = citeFormatter.remove(from: typingAttributes)
            
            performUndoable(at: applicationRange) {
                formatter.removeAttributes(from: storage, at: applicationRange)
                citeFormatter.removeAttributes(from: storage, at: applicationRange)
                
                return applicationRange
            }
        }
    }
    
    // MARK: - Attributes
    
    private func removeAttributes(managedBy formatter: AttributeFormatter, from range: NSRange) {
        let applicationRange = formatter.applicationRange(for: selectedRange, in: textStorage)
        formatter.removeAttributes(from: textStorage, at: applicationRange)
    }
    
    private func removeTypingAttributes(managedBy formatter: AttributeFormatter) {
        typingAttributes = formatter.remove(from: typingAttributes)
    }

    // MARK: - WORKAROUND: Removing paragraph styles when pressing enter in an empty paragraph

    /// Removes paragraph attributes after pressing enter in an empty paragraph.
    ///
    /// - Parameter input: the user's input.  This method must be called before the input is processed.
    ///
    func ensureRemovalOfParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: String) -> Bool {
        guard mustRemoveParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: input) else {
            return false
        }

        removeParagraphFormatting()
        
        // If there's any paragraph property that's not removed by a formatter, we'll still
        // make sure it's forcefully removed by the following calls.
        removeParagraphPropertiesFromTypingAttributes()
        removeParagraphProperties(from: selectedRange)

        return true
    }
    
    /// Removes all paragraph formatting from the typingAttributes and from the selected range.
    ///
    private func removeParagraphFormatting() {
        for formatter in paragraphFormatters {
            typingAttributes = formatter.remove(from: typingAttributes)
            formatter.removeAttributes(from: storage, at: selectedRange)
        }
    }

    /// Analyzes whether paragraph attributes should be removed after pressing enter in an empty
    /// paragraph.
    ///
    /// - Returns: `true` if we should remove paragraph attributes, otherwise it returns `false`.
    ///
    private func mustRemoveParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: String) -> Bool {
        return selectedRange.length == 0
            && input.isEndOfLine()
            && storage.string.isEmptyLine(at: selectedRange.location)
            && typingAttributesHaveRemovableParagraphStyles()
    }
    
    /// This method lets the caller know if the typing attributes have removable paragraph styles.
    /// These styles are simply anything besides <p>, which should be removed when pressing enter twice.
    ///
    /// - Returns: `true` if there are styles that can be removed
    ///
    private func typingAttributesHaveRemovableParagraphStyles() -> Bool {
        guard let paragraphStyle = typingAttributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }
        
        return paragraphStyle.hasProperty(where: { type(of: $0) != HTMLParagraph.self })
    }


    // MARK: - WORKAROUND: Removing paragraph styles when pressing backspace and removing the last character

    /// Removes paragraph attributes after pressing backspace, if the resulting document is empty.
    ///
    func ensureRemovalOfParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument() {
        guard mustRemoveParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument() else {
            return
        }

        removeParagraphPropertiesFromTypingAttributes()
        removeParagraphProperties(from: selectedRange)
    }

    /// Analyzes whether paragraph attributes should be removed from the specified
    /// location, or not, after pressing backspace.
    ///
    /// - Returns: `true` if we should remove paragraph attributes, otherwise it returns `false`.
    ///
    private func mustRemoveParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument() -> Bool {
        return storage.length == 0
    }

    // MARK: - WORKAROUND: Removing styles at EOF due to selection change

    /// Removes the Paragraph Attributes [Blockquote, Pre, Lists] at the specified range. If the range
    /// is beyond the storage's contents, the typingAttributes will be modified.
    ///
    private func removeParagraphProperties(from range: NSRange) {
        
        let paragraphRanges = storage.paragraphRanges(intersecting: range, includeParagraphSeparator: true)
        
        for paragraphRange in paragraphRanges {
            removeParagraphPropertiesFromParagraph(spanning: paragraphRange)
        }
    }
    
    private func removeParagraphPropertiesFromTypingAttributes() {
        guard let paragraphStyle = typingAttributes[.paragraphStyle] as? ParagraphStyle else {
            return
        }
        
        typingAttributes[.paragraphStyle] = paragraphStyleWithoutProperties(from: paragraphStyle)
    }
    
    private func removeParagraphPropertiesFromParagraph(spanning range: NSRange) {
        
        var attributes = storage.attributes(at: range.location, effectiveRange: nil)
        
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle else {
            return
        }
        
        attributes[.paragraphStyle] = paragraphStyleWithoutProperties(from: paragraphStyle)
        
        storage.setAttributes(attributes, range: range)
    }
    
    private func paragraphStyleWithoutProperties(from paragraphStyle: ParagraphStyle) -> ParagraphStyle {
        let newParagraphStyle = ParagraphStyle(with: paragraphStyle)
        
        // If the topmost property is a paragraph, we can keep it.  Otherwise just
        // create a new one.
        if let firstProperty = newParagraphStyle.properties.first,
            type(of: firstProperty) == HTMLParagraph.self {
            
            newParagraphStyle.properties = [firstProperty]
        } else {
            newParagraphStyle.properties = [HTMLParagraph()]
        }
        
        return newParagraphStyle
    }
}

// MARK: - Undo implementation
//
public extension TextView {

    /// Undoable Operation. Returns the Final Text Range, resulting from applying the undoable Operation
    /// Note that for Styling Operations, the Final Range will most likely match the Initial Range.
    /// For text editing it will only match the initial range if the original string was replaced with a
    /// string of the same length.
    ///
    typealias Undoable = () -> NSRange


    /// Registers an Undoable Operation, which will be applied at the specified Initial Range.
    ///
    /// - Parameters:
    ///     - initialRange: Initial Storage Range upon which we'll apply a transformation.
    ///     - block: Undoable Operation. Should return the resulting Substring's Range.
    ///
    private func performUndoable(at initialRange: NSRange, block: Undoable) {
        let originalString = storage.attributedSubstring(from: initialRange)

        let finalRange = block()

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: finalRange)
        })

        notifyTextViewDidChange()
    }
/*
    public func undoTextReplacement(of originalText: NSAttributedString, finalRange: NSRange) {

        let redoFinalRange = NSRange(location: finalRange.location, length: originalText.length)
        let redoOriginalText = storage.attributedSubstring(from: finalRange)

        storage.replaceCharacters(in: finalRange, with: originalText)
        selectedRange = redoFinalRange

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: redoOriginalText, finalRange: redoFinalRange)
        })

        notifyTextViewDidChange()
    }*/
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromOptionalNSAttributedStringKeyDictionary(_ input: [NSAttributedString.Key: Any]?) -> [String: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKeyDictionary(_ input: [NSAttributedString.Key: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

