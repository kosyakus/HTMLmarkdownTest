import Foundation

// MARK: - NSAttributedString Archive methods
//
extension NSAttributedString
{
    static let pastesboardUTI = "com.wordpress.aztec.attributedString"

    func archivedData() -> Data {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false) else { return Data() }
        return data
    }

    static func unarchive(with data: Data) -> NSAttributedString? {
        let attributedString = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSAttributedString
        return attributedString
    }
    
}
