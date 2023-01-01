import Foundation
import UIKit


/// Implemented by a class taking care of handling attachments for the storage.
///
protocol TextStorageAttachmentsDelegate: AnyObject {

    /// Provides images for attachments that are part of the storage
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - attachment: The attachment that is requesting the image.
    ///     - url: url for the image.
    ///     - success: Callback block to be invoked with the image fetched from the url.
    ///     - failure: Callback block to be invoked when an error occurs when fetching the image.
    ///
    func storage(
        _ storage: TextStorage,
        attachment: NSTextAttachment,
        imageFor url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ())

    /// Provides an image placeholder for a specified attachment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - attachment: The attachment that is requesting the image.
    ///
    /// - Returns: An Image placeholder to be rendered onscreen.
    ///
    func storage(_ storage: TextStorage, placeholderFor attachment: NSTextAttachment) -> UIImage

    /// Provides the Bounds required to represent a given attachment, within a specified line fragment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the bounds.
    ///     - attachment: NSTextAttachment about to be rendered.
    ///     - lineFragment: Line Fragment in which the glyph would be rendered.
    ///
    /// - Returns: Rect specifying the Bounds for the attachment
    ///
    func storage(_ storage: TextStorage, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect

    /// Provides the (Optional) Image Representation of the specified size, for a given Attachment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the bounds.
    ///     - attachment: NSTextAttachment about to be rendered.
    ///     - size: Expected Image Size
    ///
    /// - Returns: (Optional) UIImage representation of the attachment.
    ///
    func storage(_ storage: TextStorage, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage?
}


/// Custom NSTextStorage
///
open class TextStorage: NSTextStorage {
    
    // MARK: - HTML Conversion
    
    public let htmlConverter = HTMLConverter()
    
    // MARK: - PluginManager
    
    var pluginManager: PluginManager {
        get {
            return htmlConverter.pluginManager
        }
    }
    
    // MARK: - Storage

    var textStore = NSMutableAttributedString(string: "", attributes: nil)
    fileprivate var textStoreString = ""

    // MARK: - Delegates

    /// NOTE:
    /// `attachmentsDelegate` is an optional property. On purpose. During a Drag and Drop OP, the
    /// LayoutManager may instantiate an entire TextKit stack. Since there is absolutely no entry point
    /// in which we may set this delegate, we need to set it as optional.
    ///
    /// Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/727
    ///
    weak var attachmentsDelegate: TextStorageAttachmentsDelegate?


    // MARK: - Calculated Properties

    override open var string: String {
        return textStoreString
    }
    
    // MARK: - Range Methods

    func range<T : NSTextAttachment>(for attachment: T) -> NSRange? {
        var range: NSRange?

        textStore.enumerateAttachmentsOfType(T.self) { (currentAttachment, currentRange, stop) in
            if attachment == currentAttachment {
                range = currentRange
                stop.pointee = true
            }
        }

        return range
    }
    
    // MARK: - NSAttributedString preprocessing

    private func preprocessAttributesForInsertion(_ attributedString: NSAttributedString) -> NSAttributedString {
        let stringWithAttachments = preprocessAttachmentsForInsertion(attributedString)
        let preprocessedString = preprocessHeadingsForInsertion(stringWithAttachments)

        return preprocessedString
    }

    /// Preprocesses an attributed string's attachments for insertion in the storage.
    ///
    /// - Important: This method takes care of removing any non-image attachments too.  This may
    ///         change in future versions.
    ///
    /// - Parameters:
    ///     - attributedString: the string we need to preprocess.
    ///
    /// - Returns: the preprocessed string.
    ///
    fileprivate func preprocessAttachmentsForInsertion(_ attributedString: NSAttributedString) -> NSAttributedString {
        // Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/727:
        // If the delegate is not set, we *Explicitly* do not want to crash here.

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let finalString = NSMutableAttributedString(attributedString: attributedString)
        
        attributedString.enumerateAttribute(.attachment, in: fullRange, options: []) { (object, range, stop) in
            guard let object = object else {
                return
            }

            guard let textAttachment = object as? NSTextAttachment else {
                assertionFailure("We expected a text attachment object.")
                return
            }

            switch textAttachment {
            case _ as LineAttachment:
                break
            case let attachment as RenderableAttachment:
                attachment.delegate = self
            default:
                guard let _ = textAttachment.image else {
                    // We only suppot image attachments for now. All other attachment types are
                    // stripped for safety.
                    //
                    finalString.removeAttribute(.attachment, range: range)
                    return
                }
            }
        }

        return finalString
    }

    /// Preprocesses an attributed string that is missing a `headingRepresentation` attribute for insertion in the storage.
    ///
    /// - Important: This method adds the `headingRepresentation` attribute if it determines the string should contain it.
    ///  This works around a problem where autocorrected text didn't contain the attribute. This may change in future versions.
    ///
    /// - Parameters:
    ///     - attributedString: the string we need to preprocess.
    ///
    /// - Returns: the preprocessed string.
    ///
    fileprivate func preprocessHeadingsForInsertion(_ attributedString: NSAttributedString) -> NSAttributedString {
        // Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/pull/1334

        guard textStore.length > 0, attributedString.length > 0 else {
            return attributedString
        }

        // Get the attributes of the start of the current string in storage.
        let currentAttrs = attributes(at: 0, effectiveRange: nil)

        guard
            // the text currently in storage has a headingRepresentation key
            let headerSize = currentAttrs[.headingRepresentation],
            // the text coming in doesn't have a headingRepresentation key
            attributedString.attribute(.headingRepresentation, at: 0, effectiveRange: nil) == nil,
            // the text coming in has a paragraph style attribute
            let paragraphStyle = attributedString.attributes(at: 0, effectiveRange: nil)[.paragraphStyle] as? ParagraphStyle,
            // the paragraph style contains a property that's a Header type
            paragraphStyle.properties.contains(where: { $0 is Header })
        else {
            // Either the heading attribute wasn't present in the existing string,
            // or the attributed string already had it.
            return attributedString
        }

        let processedString = NSMutableAttributedString(attributedString: attributedString)
        processedString.addAttribute(.headingRepresentation, value: headerSize, range: attributedString.rangeOfEntireString)

        return processedString
    }

    // MARK: - Overriden Methods

    /// Retrieves the attributes for the requested character location.
    ///
    /// - Important: please note that this method returns the style at the character location, and
    ///     NOT at the caret location.  For N characters we always have N+1 character locations.
    ///
    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {

        guard textStore.length > 0 else {
            return [:]
        }

        return textStore.attributes(at: location, effectiveRange: range)
    }

    private func replaceTextStoreString(_ range: NSRange, with string: String) {
        let utf16String = textStoreString.utf16
        let startIndex = utf16String.index(utf16String.startIndex, offsetBy: range.location)
        let endIndex = utf16String.index(startIndex, offsetBy: range.length)
        textStoreString.replaceSubrange(startIndex..<endIndex, with: string)
    }
 
    override open func replaceCharacters(in range: NSRange, with str: String) {

        beginEditing()

        textStore.replaceCharacters(in: range, with: str)

        replaceTextStoreString(range, with: str)

        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        
        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {

        let preprocessedString = preprocessAttributesForInsertion(attrString)

        beginEditing()

        textStore.replaceCharacters(in: range, with: preprocessedString)

        replaceTextStoreString(range, with: attrString.string)

        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)

        endEditing()
    }

    override open func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()

        let fixedAttributes = ensureMatchingFontAndParagraphHeaderStyles(beforeApplying: attrs ?? [:], at: range)

        textStore.setAttributes(fixedAttributes, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        
        endEditing()
    }

    // MARK: - Styles: Toggling

    @discardableResult
    func toggle(formatter: AttributeFormatter, at range: NSRange) -> NSRange {
        let applicationRange = formatter.applicationRange(for: range, in: self)
        
        guard applicationRange.length > 0 else {
            return applicationRange
        }

        return formatter.toggle(in: self, at: applicationRange)
    }

    // MARK: - Attachments

    private func enumerateRenderableAttachments(in text: NSAttributedString, range: NSRange? = nil, block: ((RenderableAttachment, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)) {
        let range = range ?? NSMakeRange(0, length)
        text.enumerateAttribute(.attachment, in: range, options: []) { (object, range, stop) in
            if let object = object as? RenderableAttachment {
                block(object, range, stop)
            }
        }
    }

    // MARK: - HTML Interaction

    open func getHTML(prettify: Bool = false) -> String {
        return htmlConverter.html(from: self, prettify: prettify)
    }

    open func getHTML(prettify: Bool = false, range: NSRange) -> String {
        return htmlConverter.html(from: self.attributedSubstring(from: range), prettify: prettify)
    }

    open func getHTML(prettify: Bool = false, from attributedString: NSAttributedString) -> String {
        return htmlConverter.html(from: attributedString, prettify: prettify)
    }
    
    func setHTML(_ html: String, defaultAttributes: [NSAttributedString.Key: Any]) {
        let originalLength = length
        let attrString = htmlConverter.attributedString(from: html, defaultAttributes: defaultAttributes)

        textStore = NSMutableAttributedString(attributedString: attrString)
        textStoreString = textStore.string
        
        setupAttachmentDelegates()

        edited([.editedAttributes, .editedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
    }
    
    private func setupAttachmentDelegates() {
        enumerateRenderableAttachments(in: textStore, block: { [weak self] (attachment, _, _) in
            attachment.delegate = self
        })
    }
}


// MARK: - Header Font Attribute Fixes
//
private extension TextStorage {

    /// Ensures the font style is consistent with the paragraph header style that's about to be applied.
    ///
    /// - Parameters:
    ///   - attrs: NSAttributedString attributes that are about to be applied.
    ///   - range: Range that's about to be affected by the new Attributes collection.
    ///
    /// - Returns: Collection of attributes with the Font Attribute corrected, if needed.
    ///
    func ensureMatchingFontAndParagraphHeaderStyles(beforeApplying attrs: [NSAttributedString.Key: Any], at range: NSRange) -> [NSAttributedString.Key: Any] {
        let newStyle = attrs[.paragraphStyle] as? ParagraphStyle
        let oldStyle = textStore.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? ParagraphStyle

        let newLevel = newStyle?.headers.last?.level ?? .none
        let oldLevel = oldStyle?.headers.last?.level ?? .none

        guard oldLevel != newLevel && newLevel != .none else {
            return attrs
        }
        
        return fixFontAttribute(in: attrs, headerLevel: newLevel)
    }

    /// This helper re-applies the HeaderFormatter to the specified collection of attributes, so that the Font Attribute is explicitly set,
    /// and it matches the target HeaderLevel.
    ///
    /// - Parameters:
    ///   - attrs: NSAttributedString attributes that are about to be applied.
    ///   - headerLevel: HeaderLevel specified by the ParagraphStyle, associated to the application range.
    ///
    /// - Returns: Collection of attributes with the Font Attribute corrected, so that it matches the specified HeaderLevel.
    ///
    private func fixFontAttribute(in attrs: [NSAttributedString.Key: Any], headerLevel: Header.HeaderType) ->  [NSAttributedString.Key: Any] {
        let formatter = HeaderFormatter(headerLevel: headerLevel)
        return formatter.apply(to: attrs)
    }
}

// MARK: - TextStorage: RenderableAttachmentDelegate Methods
//
extension TextStorage: RenderableAttachmentDelegate {

    public func attachment(_ attachment: NSTextAttachment, imageForSize size: CGSize) -> UIImage? {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        return delegate.storage(self, imageFor: attachment, with: size)
    }

    public func attachment(_ attachment: NSTextAttachment, boundsForLineFragment fragment: CGRect) -> CGRect {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        return delegate.storage(self, boundsFor: attachment, with: fragment)
    }
}
