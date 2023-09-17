//
//  VSwipy.swift
//  Swipy
//
//  Created by hamed on 1/29/23.
//

import SwiftUI
import Combine

public struct VSwipy<T: Identifiable, ItemView: View>: View {
    public typealias OnItemView = (T) -> (ItemView)
    public let viewModel: VSwipyViewModel<T>
    public let onItemView: OnItemView

    public init(viewModel: VSwipyViewModel<T>, @ViewBuilder onItemView: @escaping OnItemView){
        self.viewModel = viewModel
        self.onItemView = onItemView
    }

    public var body: some View {
        GeometryReader { reader in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SwipyForLoop(onItemView: onItemView)
                        .environmentObject(viewModel)
                }
            }
            .onAppear {
                viewModel.containerSize = reader.size.height
                viewModel.animateObjectWillChange()
            }
            .onReceive(Just(viewModel.selection)) { newValue in
                viewModel.onSelection(newValue)
            }
        }
    }
}

public struct SwipyForLoop<T: Identifiable, ItemView: View>: View {
    public typealias OnItemView = (T) -> (ItemView)
    public let onItemView: OnItemView
    @EnvironmentObject var viewModel: VSwipyViewModel<T>

    public var body: some View {
        ForEach(viewModel.items) { item in
            RowItemView(item: item, onItemView: onItemView)
        }
    }
}

public struct RowItemView<T: Identifiable, ItemView: View>: View {
    let item: T
    public typealias OnItemView = (T) -> (ItemView)
    public let onItemView: OnItemView
    @EnvironmentObject var viewModel: VSwipyViewModel<T>

    var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                viewModel.dragValue = value
                viewModel.onDragging()
            }
            .onEnded { _ in
                viewModel.onDrageFinished()
            }
    }

    var longGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.002)
            .onEnded { finished in
                viewModel.onLongPressing(true)
            }
    }

    var combinedGesture: some Gesture {
        SequenceGesture(longGesture, drag)
    }

    public init(item: T, onItemView: @escaping OnItemView) {
        self.item = item
        self.onItemView = onItemView
    }

    public var body: some View {
        onItemView(item)
            .frame(maxHeight: viewModel.containerSize)
            .scaleEffect(x: viewModel.isDragging ? viewModel.scaleX : 1, y: viewModel.isDragging ? viewModel.scaleY : 1)
            .rotation3DEffect(.degrees(viewModel.scaleDegree), axis: (x: viewModel.scale3d, y: 0, z: 0))
            .offset(CGSize(width: 0, height: viewModel.offsetValue))
            .gesture(combinedGesture)
            .onLongPressGesture(minimumDuration: 0.002, maximumDistance: 0) {} onPressingChanged: { isPressing in
                viewModel.onLongPressing(isPressing)
            }
    }
}
