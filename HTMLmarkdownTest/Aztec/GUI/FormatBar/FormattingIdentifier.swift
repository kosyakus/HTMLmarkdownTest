import Foundation
import UIKit

public struct FormattingIdentifier: RawRepresentable, Hashable {
    
    public typealias RawValue = String
    
    public var rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension FormattingIdentifier {
    public static let blockquote = FormattingIdentifier("blockquote")
    public static let bold = FormattingIdentifier("bold")
    public static let code = FormattingIdentifier("code")
    public static let italic = FormattingIdentifier("italic")
    public static let media = FormattingIdentifier("media")
    public static let more = FormattingIdentifier("more")
    public static let header1 = FormattingIdentifier("header1")
    public static let header2 = FormattingIdentifier("header2")
    public static let header3 = FormattingIdentifier("header3")
    public static let header4 = FormattingIdentifier("header4")
    public static let header5 = FormattingIdentifier("header5")
    public static let header6 = FormattingIdentifier("header6")
    public static let horizontalruler = FormattingIdentifier("horizontalruler")
    public static let link = FormattingIdentifier("link")
    public static let orderedlist = FormattingIdentifier("orderedlist")
    public static let p = FormattingIdentifier("p")
    public static let sourcecode = FormattingIdentifier("sourcecode")
    public static let strikethrough = FormattingIdentifier("strikethrough")
    public static let underline = FormattingIdentifier("underline")
    public static let unorderedlist = FormattingIdentifier("unorderedlist")
    public static let mark = FormattingIdentifier("mark")
}

extension FormattingIdentifier {
    
    var iconImage: UIImage {
        
        switch(self) {
        case .p:
            return UIImage.systemImage("textformat.size")
        case .bold:
            return UIImage.systemImage("bold")
        case .italic:
            return UIImage.systemImage("italic")
        case .underline:
            return UIImage.systemImage("underline")
        case .strikethrough:
            return UIImage.systemImage("strikethrough")
        case .blockquote:
            return UIImage.systemImage("text.quote")
        case .orderedlist:
            return UIImage.systemImage("list.number")
        case .unorderedlist:
            return UIImage.systemImage("list.bullet")
        case .horizontalruler:
            return UIImage.systemImage("minus")
        case .more:
            return UIImage.systemImage("textformat.abc.dottedunderline")
        case .header1:
            return UIImage.systemImage("textformat.size")
        case .header2:
            return UIImage.systemImage("textformat.size")
        case .header3:
            return UIImage.systemImage("textformat.size")
        case .header4:
            return UIImage.systemImage("textformat.size")
        case .header5:
            return UIImage.systemImage("textformat.size")
        case .header6:
            return UIImage.systemImage("textformat.size")
        default:
            return UIImage.systemImage("info")
        }
    }
    
    var accessibilityIdentifier: String {
        switch(self) {
        case .p:
            return "formatToolbarSelectParagraphStyle"
        case .bold:
            return "formatToolbarToggleBold"
        case .italic:
            return "formatToolbarToggleItalic"
        case .underline:
            return "formatToolbarToggleUnderline"
        case .strikethrough:
            return "formatToolbarToggleStrikethrough"
        case .blockquote:
            return "formatToolbarToggleBlockquote"
        case .orderedlist:
            return "formatToolbarToggleListOrdered"
        case .unorderedlist:
            return "formatToolbarToggleListUnordered"
        case .horizontalruler:
            return "formatToolbarInsertHorizontalRuler"
        case .more:
            return "formatToolbarInsertMore"
        case .header1:
            return "formatToolbarToggleH1"
        case .header2:
            return "formatToolbarToggleH2"
        case .header3:
            return "formatToolbarToggleH3"
        case .header4:
            return "formatToolbarToggleH4"
        case .header5:
            return "formatToolbarToggleH5"
        case .header6:
            return "formatToolbarToggleH6"
        default:
            return ""
        }
    }
    
    var accessibilityLabel: String {
        switch(self) {
            //        case .media:
            //            return NSLocalizedString("Insert media", comment: "Accessibility label for insert media button on formatting toolbar.")
        case .p:
            return NSLocalizedString("Select paragraph style", comment: "Accessibility label for selecting paragraph style button on formatting toolbar.")
        case .bold:
            return NSLocalizedString("Bold", comment: "Accessibility label for bold button on formatting toolbar.")
        case .italic:
            return NSLocalizedString("Italic", comment: "Accessibility label for italic button on formatting toolbar.")
        case .underline:
            return NSLocalizedString("Underline", comment: "Accessibility label for underline button on formatting toolbar.")
        case .strikethrough:
            return NSLocalizedString("Strike Through", comment: "Accessibility label for strikethrough button on formatting toolbar.")
        case .blockquote:
            return NSLocalizedString("Block Quote", comment: "Accessibility label for block quote button on formatting toolbar.")
        case .orderedlist:
            return NSLocalizedString("Ordered List", comment: "Accessibility label for Ordered list button on formatting toolbar.")
        case .unorderedlist:
            return NSLocalizedString("Unordered List", comment: "Accessibility label for unordered list button on formatting toolbar.")
        case .horizontalruler:
            return NSLocalizedString("Insert Horizontal Ruler", comment: "Accessibility label for insert horizontal ruler button on formatting toolbar.")
        case .more:
            return NSLocalizedString("More", comment:"Accessibility label for the More button on formatting toolbar.")
        case .header1:
            return NSLocalizedString("Heading 1", comment: "Accessibility label for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return NSLocalizedString("Heading 2", comment: "Accessibility label for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return NSLocalizedString("Heading 3", comment: "Accessibility label for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return NSLocalizedString("Heading 4", comment: "Accessibility label for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return NSLocalizedString("Heading 5", comment: "Accessibility label for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return NSLocalizedString("Heading 6", comment: "Accessibility label for selecting h6 paragraph style button on the formatting toolbar.")
        default:
            return ""
        }
        
    }
}
