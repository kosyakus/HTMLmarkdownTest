//
//  TextViewController.swift
//  HTMLmarkdownTest
//
//  Created by Natalia Sinitsyna on 28.12.2022.
//

import Foundation
import MobileCoreServices
import Photos
import UIKit

protocol FirstViewControllerDelegate {
    func movedBack(text: NSMutableAttributedString)
}

class TextViewController: UIViewController {
    
//    @IBOutlet var textView: TextView!
    
    fileprivate(set) lazy var formatBar: FormatBar = {
        return self.createToolbar()
    }()
    
    private var richTextView: TextView {
        get {
            return editorView.richTextView
        }
    }
    
    private var htmlTextView: UITextView {
        get {
            return editorView.htmlTextView
        }
    }
    
    fileprivate(set) lazy var editorView: EditorView = {
        let defaultHTMLFont: UIFont
        
        defaultHTMLFont = UIFontMetrics.default.scaledFont(for: Constants.defaultContentFont)
        
        let editorView = EditorView(
            defaultFont: Constants.defaultContentFont,
            defaultHTMLFont: defaultHTMLFont,
            defaultParagraphStyle: .default,
            defaultMissingImage: Constants.defaultMissingImage)
        
        editorView.clipsToBounds = false
        setupHTMLTextView(editorView.htmlTextView)
        setupRichTextView(editorView.richTextView)
        
        return editorView
    }()
    
    private func setupRichTextView(_ textView: TextView) {
        if wordPressMode {
            textView.load(WordPressPlugin())
        }
        
        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)
        
        textView.delegate = self
        textView.formattingDelegate = self
        textView.accessibilityIdentifier = "richContentView"
        textView.clipsToBounds = false
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }
    
    private func setupHTMLTextView(_ textView: UITextView) {
        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(htmlTextView: textView, accessibilityLabel: accessibilityLabel)
        
        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.clipsToBounds = false
        textView.adjustsFontForContentSizeCategory = true
        
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }
    
    
    let sampleHTML: String?
    let wordPressMode: Bool
    let attributedString: NSMutableAttributedString?
    
    private lazy var optionsTablePresenter = OptionsTablePresenter(presentingViewController: self, presentingTextView: richTextView)
    
    // MARK: - Lifecycle Methods
    
    init(withText: NSMutableAttributedString, wordPressMode: Bool) {
        
        self.attributedString = withText
        self.sampleHTML = ""
        self.wordPressMode = wordPressMode
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        sampleHTML = nil
        wordPressMode = false
        attributedString = NSMutableAttributedString(string: "")
        
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var delegate: FirstViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        edgesForExtendedLayout = UIRectEdge()
        view.addSubview(editorView)
        
        editorView.richTextView.textContainer.lineFragmentPadding = 0
        // color setup
        if #available(iOS 13.0, *) {
            view.backgroundColor = .orange //UIColor.systemBackground
            editorView.htmlTextView.textColor = UIColor.label
            editorView.richTextView.textColor = UIColor.label
            editorView.richTextView.blockquoteBackgroundColor = UIColor.secondarySystemBackground
            editorView.richTextView.preBackgroundColor = UIColor.secondarySystemBackground
            editorView.richTextView.blockquoteBorderColors = [.secondarySystemFill, .systemTeal, .systemBlue]
            var attributes = editorView.richTextView.linkTextAttributes
            attributes?[.foregroundColor] =  UIColor.link
        } else {
            view.backgroundColor = UIColor.white
        }
        //Don't allow scroll while the constraints are being setup and text set
        editorView.isScrollEnabled = false
        configureConstraints()
        
        let html: String
        
        if let sampleHTML = sampleHTML {
            html = sampleHTML
        } else {
            html = ""
        }
        editorView.setHTML(html)
        editorView.becomeFirstResponder()
        
        navigationController?.title = "My custom description"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(moveBack))
        setUpAttributedString()
    }
    
    @objc func moveBack() {
        delegate?.movedBack(text: editorView.richTextView.storage.textStore)
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Reanable scroll after setup is done
        editorView.isScrollEnabled = true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        optionsTablePresenter.dismiss()
    }
    
    func setUpAttributedString() {
        editorView.richTextView.attributedText = attributedString ?? NSMutableAttributedString(string: "")
    }
    
    func updateScrollInsets() {
        var scrollInsets = editorView.contentInset
        var rightMargin = (view.frame.maxX - editorView.frame.maxX)
        rightMargin -= view.safeAreaInsets.right
        
        scrollInsets.right = -rightMargin
        editorView.scrollIndicatorInsets = scrollInsets
    }
    
    
    // MARK: - Configuration Methods
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    private func configureConstraints() {
        
        let layoutGuide = view.readableContentGuide
        
        NSLayoutConstraint.activate([
            editorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            editorView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    
    private func configureDefaultProperties(for textView: TextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.font = Constants.defaultContentFont
        textView.keyboardDismissMode = .interactive
        if #available(iOS 13.0, *) {
            textView.textColor = UIColor.label
            textView.defaultTextColor = UIColor.label
        } else {
            // Fallback on earlier versions
            textView.textColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1)
            textView.defaultTextColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1)
        }
        textView.linkTextAttributes = [.foregroundColor: UIColor(red: 0x01 / 255.0, green: 0x60 / 255.0, blue: 0x87 / 255.0, alpha: 1), NSAttributedString.Key.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)]
    }
    
    private func configureDefaultProperties(htmlTextView textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.font = Constants.defaultContentFont
        textView.keyboardDismissMode = .interactive
        if #available(iOS 13.0, *) {
            textView.textColor = UIColor.label
            if let htmlStorage = textView.textStorage as? HTMLStorage {
                htmlStorage.textColor = UIColor.label
            }
        } else {
            // Fallback on earlier versions
            textView.textColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1)
        }
        textView.linkTextAttributes = [.foregroundColor: UIColor(red: 0x01 / 255.0, green: 0x60 / 255.0, blue: 0x87 / 255.0, alpha: 1), NSAttributedString.Key.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)]
    }
    
    // MARK: - Helpers
    
    @IBAction func toggleEditingMode() {
        formatBar.overflowToolbar(expand: true)
        editorView.toggleEditingMode()
    }
    
    // MARK: - Options VC
    
    private let formattingIdentifiersWithOptions: [FormattingIdentifier] = [.orderedlist, .unorderedlist, .p, .header1, .header2, .header3, .header4, .header5, .header6]
    
    private func formattingIdentifierHasOptions(_ formattingIdentifier: FormattingIdentifier) -> Bool {
        return formattingIdentifiersWithOptions.contains(formattingIdentifier)
    }
    
    // MARK: - Keyboard Handling
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        refreshInsets(forKeyboardFrame: keyboardFrame)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        refreshInsets(forKeyboardFrame: keyboardFrame)
        optionsTablePresenter.dismiss()
    }
    
    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        
        // The reason why we're converting the keyboard coordinates instead of just using
        // keyboardFrame.height, is that we need to make sure the insets take into account the
        // possibility that there could be other views on top or below the text view.
        // keyboardInset is basically the distance between the top of the keyboard
        // and the bottom of the text view.
        let localKeyboardOrigin = view.convert(keyboardFrame.origin, from: nil)
        let keyboardInset = max(view.frame.height - localKeyboardOrigin.y, 0)
        
        let contentInset = UIEdgeInsets(
            top: editorView.contentInset.top,
            left: 0,
            bottom: keyboardInset,
            right: 0)
        
        editorView.contentInset = contentInset
        updateScrollInsets()
    }
    
    
    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? FormatBar else {
            return
        }
        
        let identifiers: Set<FormattingIdentifier>
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        
        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }
    
    override var keyCommands: [UIKeyCommand] {
        
        if richTextView.isFirstResponder {
            return [ UIKeyCommand(title: NSLocalizedString("Bold", comment: "Discoverability title for bold formatting keyboard shortcut."), action:#selector(toggleBold), input:"B", modifierFlags: .command, propertyList: nil, alternates: []),
                     UIKeyCommand(title:NSLocalizedString("Italic", comment: "Discoverability title for italic formatting keyboard shortcut."), action:#selector(toggleItalic), input:"I", modifierFlags: .command ),
                     UIKeyCommand(title: NSLocalizedString("Strikethrough", comment:"Discoverability title for strikethrough formatting keyboard shortcut."), action:#selector(toggleStrikethrough), input:"S", modifierFlags: [.command]),
                     UIKeyCommand(title: NSLocalizedString("Underline", comment:"Discoverability title for underline formatting keyboard shortcut."), action:#selector(TextViewController.toggleUnderline(_:)), input:"U", modifierFlags: .command ),
                     UIKeyCommand(title: NSLocalizedString("Block Quote", comment: "Discoverability title for block quote keyboard shortcut."), action: #selector(toggleBlockquote), input:"Q", modifierFlags:[.command,.alternate]),
                     UIKeyCommand(title:NSLocalizedString("Bullet List", comment: "Discoverability title for bullet list keyboard shortcut."), action:#selector(toggleUnorderedList), input:"U", modifierFlags:[.command, .alternate]),
                     UIKeyCommand(title:NSLocalizedString("Numbered List", comment:"Discoverability title for numbered list keyboard shortcut."), action:#selector(toggleOrderedList), input:"O", modifierFlags:[.command, .alternate]),
            ]
        } else if htmlTextView.isFirstResponder {
            return [UIKeyCommand(title:NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."), action: #selector(toggleEditingMode), input: "H", modifierFlags: [.command, .shift])
            ]
        }
        return []
    }
    
    
    // MARK: - Sample Content
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if richTextView.resignFirstResponder() {
            richTextView.becomeFirstResponder()
        }
        
        if htmlTextView.resignFirstResponder() {
            htmlTextView.becomeFirstResponder()
        }
    }
}

extension TextViewController : UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
        changeRichTextInputView(to: nil)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case richTextView:
            updateFormatBar()
        default:
            break
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        switch textView {
        case richTextView:
            formatBar.enabled = true
        case htmlTextView:
            formatBar.enabled = false
            
            // Disable the bar, except for the source code button
            let htmlButton = formatBar.items.first(where: { $0.identifier == FormattingIdentifier.sourcecode.rawValue })
            htmlButton?.isEnabled = true
        default: break
        }
        
        textView.inputAccessoryView = formatBar
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}

extension TextViewController : TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        updateFormatBar()
    }
}

extension TextViewController {
    enum EditMode {
        case richText
        case html
        
        mutating func toggle() {
            switch self {
            case .html:
                self = .richText
            case .richText:
                self = .html
            }
        }
    }
}

// MARK: - Format Bar Delegate

extension TextViewController : FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
    }
    
    func formatBar(_ formatBar: FormatBar, didChangeOverflowState state: FormatBarOverflowState) {
        switch state {
        case .hidden:
            print("Format bar collapsed")
        case .visible:
            print("Format bar expanded")
        }
    }
}

// MARK: - Format Bar Actions
extension TextViewController {
    func handleAction(for barItem: FormatBarItem) {
        guard let identifier = barItem.identifier,
              let formattingIdentifier = FormattingIdentifier(rawValue: identifier) else {
            return
        }
        
        if !formattingIdentifierHasOptions(formattingIdentifier) {
            optionsTablePresenter.dismiss()
        }
        
        switch formattingIdentifier {
        case .bold:
            toggleBold()
        case .italic:
            toggleItalic()
        case .underline:
            toggleUnderline()
        case .strikethrough:
            toggleStrikethrough()
        case .blockquote:
            toggleBlockquote()
        case .unorderedlist, .orderedlist:
            toggleList(fromItem: barItem)
        case .p, .header1, .header2, .header3, .header4, .header5, .header6:
            toggleHeader(fromItem: barItem)
        case .horizontalruler:
            insertHorizontalRuler()
        default:
            break
        }
        
        updateFormatBar()
    }
    
    @objc func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }
    
    
    @objc func toggleItalic() {
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }
    
    
    func toggleUnderline() {
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }
    
    
    @objc func toggleStrikethrough() {
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }
    
    @objc func toggleBlockquote() {
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }
    
    func insertHorizontalRuler() {
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }
    
    func toggleHeader(fromItem item: FormatBarItem) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }
        
        let options = Constants.headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize))
            ]
            
            let title = NSAttributedString(string: headerType.description, attributes: attributes)
            return OptionsTableViewOption(image: headerType.iconImage, title: title)
        }
        
        let selectedIndex = Constants.headers.firstIndex(of: headerLevelForSelectedText())
        let optionsTableViewController = OptionsTableViewController(options: options)
        optionsTableViewController.cellDeselectedTintColor = .gray
        
        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: selectedIndex,
            onSelect: { [weak self] selected in
                guard let range = self?.richTextView.selectedRange else {
                    return
                }
                
                self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
                self?.optionsTablePresenter.dismiss()
            })
    }
    
    func toggleList(fromItem item: FormatBarItem) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }
        
        let options = Constants.lists.map { (listType) -> OptionsTableViewOption in
            return OptionsTableViewOption(image: listType.iconImage, title: NSAttributedString(string: listType.description, attributes: [:]))
        }
        
        var index: Int? = nil
        if let listType = listTypeForSelectedText() {
            index = Constants.lists.firstIndex(of: listType)
        }
        
        let optionsTableViewController = OptionsTableViewController(options: options)
        optionsTableViewController.cellDeselectedTintColor = .gray
        
        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: index,
            onSelect: { [weak self] selected in
                guard let range = self?.richTextView.selectedRange else { return }
                
                let listType = Constants.lists[selected]
                switch listType {
                case .unordered:
                    self?.richTextView.toggleUnorderedList(range: range)
                case .ordered:
                    self?.richTextView.toggleOrderedList(range: range)
                }
                
                self?.optionsTablePresenter.dismiss()
            })
    }
    
    @objc func toggleUnorderedList() {
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }
    
    @objc func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }
    
    func changeRichTextInputView(to: UIView?) {
        if richTextView.inputView == to {
            return
        }
        
        richTextView.inputView = to
        richTextView.reloadInputViews()
    }
    
    func headerLevelForSelectedText() -> Header.HeaderType {
        var identifiers = Set<FormattingIdentifier>()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: Header.HeaderType] = [
            .header1 : .h1,
            .header2 : .h2,
            .header3 : .h3,
            .header4 : .h4,
            .header5 : .h5,
            .header6 : .h6,
        ]
        for (key,value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        return .none
    }
    
    func listTypeForSelectedText() -> TextList.Style? {
        var identifiers = Set<FormattingIdentifier>()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: TextList.Style] = [
            .orderedlist : .ordered,
            .unorderedlist : .unordered
        ]
        for (key,value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        
        return nil
    }
    
//    func insertMoreAttachment() {
//        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
//    }
//
    @objc func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
        else {
            return
        }
        
        insertAction.isEnabled = !urlFieldText.isEmpty
    }
    
    @objc func tabOnTitle() {
        if editorView.becomeFirstResponder() {
            editorView.selectedTextRange = editorView.htmlTextView.textRange(from: editorView.htmlTextView.endOfDocument, to: editorView.htmlTextView.endOfDocument)
        }
    }
    
    // MARK: -
    
    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        let button = FormatBarItem(image: identifier.iconImage, identifier: identifier.rawValue)
        button.accessibilityLabel = identifier.accessibilityLabel
        button.accessibilityIdentifier = identifier.accessibilityIdentifier
        return button
    }
    
    func createToolbar() -> FormatBar {
        //        let mediaItem = makeToolbarButton(identifier: .media)
        let scrollableItems = scrollableItemsForToolbar
        let overflowItems = overflowItemsForToolbar
        
        let toolbar = FormatBar()
        
        if #available(iOS 13.0, *) {
            toolbar.backgroundColor = UIColor.systemGroupedBackground
            toolbar.tintColor = UIColor.secondaryLabel
            toolbar.highlightedTintColor = UIColor.systemBlue
            toolbar.selectedTintColor = UIColor.systemBlue
            toolbar.disabledTintColor = .systemGray4
            toolbar.dividerTintColor = UIColor.separator
        } else {
            toolbar.tintColor = .gray
            toolbar.highlightedTintColor = .blue
            toolbar.selectedTintColor = view.tintColor
            toolbar.disabledTintColor = .lightGray
            toolbar.dividerTintColor = .gray
        }
        
        toolbar.overflowToggleIcon = UIImage.init(systemName: "ellipsis")!
        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0)
        toolbar.autoresizingMask = [ .flexibleHeight ]
        toolbar.formatter = self
        
        toolbar.setDefaultItems(scrollableItems,
                                overflowItems: overflowItems)
        
        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }
        
        return toolbar
    }
    
    var scrollableItemsForToolbar: [FormatBarItem] {
        let headerButton = makeToolbarButton(identifier: .p)
        
        var alternativeIcons = [String: UIImage]()
        let headings = Constants.headers.suffix(from: 1) // Remove paragraph style
        for heading in headings {
            alternativeIcons[heading.formattingIdentifier.rawValue] = heading.iconImage
        }
        
        headerButton.alternativeIcons = alternativeIcons
        
        
        let listButton = makeToolbarButton(identifier: .unorderedlist)
        var listIcons = [String: UIImage]()
        for list in Constants.lists {
            listIcons[list.formattingIdentifier.rawValue] = list.iconImage
        }
        
        listButton.alternativeIcons = listIcons
        
        return [
            headerButton,
            listButton,
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
        ]
    }
    
    var overflowItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .horizontalruler),
        ]
    }
    
}


extension TextViewController {
    
    static var tintedMissingImage: UIImage = {
        if #available(iOS 13.0, *) {
            return UIImage.init(systemName: "photo")!.withTintColor(.label)
        } else {
            // Fallback on earlier versions
            return UIImage.init(systemName: "photo")!
        }
    }()
    
    struct Constants {
        static let defaultContentFont   = UIFont.systemFont(ofSize: 14)
        static let defaultHtmlFont      = UIFont.systemFont(ofSize: 24)
        static let defaultMissingImage  = tintedMissingImage
        static let formatBarIconSize    = CGSize(width: 20.0, height: 20.0)
        static let headers              = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                = [TextList.Style.unordered, .ordered]
        static let moreAttachmentText   = "more"
        static let titleInsets          = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        static var mediaMessageAttributes: [NSAttributedString.Key: Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                                                             .paragraphStyle: paragraphStyle,
                                                             .foregroundColor: UIColor.white]
            return attributes
        }
    }
}

