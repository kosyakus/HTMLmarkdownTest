//
//  AttributedString+htmlConverter.swift
//  Evernum
//
//  Created by Natalia Sinitsyna on 10.01.2023.
//

import Foundation

extension NSAttributedString {
    
    func convertAttributedStringToHTMLString() -> String? {
        var resultHtmlText: String?
        do {
            let range = NSRange(location: 0, length: self.length)
            let attributes = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]

            let dataFromAttributedString = try self.data(from: range, documentAttributes: attributes)

            if let htmlString = String(data: dataFromAttributedString, encoding: .utf8) {
                resultHtmlText = htmlString
            }
        }
        catch {
            print("failed to convert to html!!! \n>\(string)<\n")
        }
        return resultHtmlText
    }
}

extension NSAttributedString {
    func convertAttrStr2Html() -> String? {
//    var attributedString2Html: String? {
        do {
            let data = try self.data(from: NSRange(location: 0, length: self.length))
//            let htmlData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes:[.documentType: NSAttributedString.DocumentType.html]);
            return String.init(data: data, encoding: String.Encoding.utf8)
        } catch {
            print("error:", error)
            return nil
        }
    }
}

extension String {
    func convertHTMLStringToAttributedString() -> NSMutableAttributedString? {
        var resultAttributedString: NSMutableAttributedString?
        let data = Data(self.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            resultAttributedString = NSMutableAttributedString(attributedString: attributedString)
        }
        return resultAttributedString
    }
}
