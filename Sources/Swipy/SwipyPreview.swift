//
//  Preview.swift
//  SwiftUISamples
//
//  Created by hamed on 1/30/23.
//

import SwiftUI

fileprivate let users:[User] = [
    .init(name: "Hamed", mobile: "02666999998", imageName: "square.and.arrow.up.circle.fill"),
    .init(name: "John", mobile: "09125555555", imageName: "square.and.pencil.circle.fill"),
    .init(name: "Sam", mobile: "09125555555", imageName: "trash.circle.fill"),
    .init(name: "devon", mobile: "09125555555", imageName: "pencil.circle.fill"),
]

fileprivate struct User: Identifiable {
    let id = UUID()
    let name: String
    let mobile: String
    let imageName: String
}

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

internal protocol SwipyProtocol {
    associatedtype Item: Identifiable
    var items: [Item] { get set }
}

fileprivate struct SwipyPreview: View {
    @State var selectedItem: User?
    let containerHeight: CGFloat = 100

    var body: some View {        
        ZStack {
            Color.red.opacity(0.5)
            VStack {
                Swipy(users, containerHeight: containerHeight, edgeBouncerAmount: 10) { user in
                    HStack {
                        Image(systemName: user.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .cornerRadius(24)
                            .padding()
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .foregroundColor(.primary)

                            HStack {
                                Text(user.mobile)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .frame(minHeight: 0, maxHeight: containerHeight)
                    .cornerRadius(24)
                    .background(Color.white)
                } onSwipe: { item in
                    selectedItem = item
                }
                .frame(minHeight: 0, maxHeight: containerHeight)
                .background(Color.black)
                .cornerRadius(24)

                if let selectedItem = selectedItem {
                    Text("\(selectedItem.name)")
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SwipyPreview()
    }
}
