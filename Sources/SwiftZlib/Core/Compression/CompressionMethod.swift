//
//  CompressionMethod.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum CompressionMethod: Int32 {
    case deflate = 8
    public var zlibMethod: Int32 { rawValue }
}
