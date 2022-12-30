//
//  UIImage+extension.swift
//  HTMLmarkdownTest
//
//  Created by Natalia Sinitsyna on 30.12.2022.
//

import Foundation
import UIKit

extension UIImage {
    
    static func systemImage(_ name: String) -> UIImage {
        guard let image = UIImage(systemName: name) else {
            assertionFailure("Missing system image: \(name)")
            return UIImage()
        }
        
        return image
    }
}
