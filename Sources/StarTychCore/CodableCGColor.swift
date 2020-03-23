//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
//

import CoreImage

struct CodableCGColor: Codable {
    let color: CGColor
    
    init(with aColor: CGColor) {
        color = aColor
    }
    
    enum ComponentCodingKeys: CodingKey, CaseIterable {
        case red
        case green
        case blue
        case alpha
    }
    
    func encode(to encoder: Encoder) throws {
        let encodableColor = CIColor(cgColor: color)
        
        var container = encoder.container(keyedBy: ComponentCodingKeys.self)
        try container.encode(encodableColor.red, forKey: .red)
        try container.encode(encodableColor.green, forKey: .green)
        try container.encode(encodableColor.blue, forKey: .blue)
        try container.encode(encodableColor.alpha, forKey: .alpha)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ComponentCodingKeys.self)
        let red = try container.decode(CGFloat.self, forKey: .red)
        let green = try container.decode(CGFloat.self, forKey: .green)
        let blue = try container.decode(CGFloat.self, forKey: .blue)
        let alpha = try container.decode(CGFloat.self, forKey: .alpha)
        
        let decodedCIColor = CIColor(red: red, green: green, blue: blue, alpha: alpha)
        guard let decodedCGColor = CGColor(colorSpace: decodedCIColor.colorSpace, components: decodedCIColor.components) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: ComponentCodingKeys.allCases, debugDescription: "Could not build CGColor from decoded CIColor"))
        }
        
        color = decodedCGColor
    }
}
