//
//  Swipy+.swift
//  Swipy
//
//  Created by hamed on 1/29/23.
//

import Foundation

extension Int {
    internal var cgFloatValue: CGFloat {
        CGFloat(self)
    }
}

extension CGFloat {
    internal var intValue: Int {
        Int(self)
    }
}

public protocol SwipyProtocol {
    associatedtype Item: Identifiable
    var items: [Item] { get set }
}
