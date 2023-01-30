//
//  ContentView.swift
//  SwiftUISamples
//
//  Created by hamed on 1/29/23.
//

import SwiftUI

public struct Swipy<T: Identifiable, ItemView: View>: View, SwipyProtocol {
    public typealias Item = T

    public var containerHeight: CGFloat = 100
    public var containerWidth: CGFloat = 346
    public var containerCornerRadius: CGFloat = 24
    public var edgeBouncerAmount: CGFloat = 10
    public var onTouchDownScaleX: CGFloat = 0.95
    public var maxScaleDownX: CGFloat = 0.85
    public var maxScaleDownY: CGFloat = 0.85
    public var percentageToSwipe: CGFloat = 0.02
    public var animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2)

    @State private var offsetY: CGFloat = .zero
    @State private var scaleY: CGFloat = 1
    @State private var scaleX: CGFloat = 1
    @State private var isDragging = false
    @State private var draggingIndex: Int = 0
    @State private var dragValue: DragGesture.Value?


    private var isTranslationGreaterThanTenPercent: Bool { abs(trHeight) > (containerHeight * percentageToSwipe) }
    private var trHeight: CGFloat { dragValue?.translation.height ?? 0 }
    private var trWidth: CGFloat { dragValue?.translation.width ?? 0 }
    private var isTopIndex: Bool { draggingIndex == 0 }
    private var startIndex: Int { items.startIndex }
    private var lastIndex: Int { items.endIndex - 1 }
    private var isLastIndex: Bool { draggingIndex == lastIndex }
    private var isGreaterThanLastIndex: Bool { draggingIndex > lastIndex }
    private var isDraggingDown: Bool { dragValue?.translation.height ?? 0 > 0 }
    private var isDraggingUp: Bool { dragValue?.translation.height ?? 0 < 0 }
    private var maxAllowedDraggUp: CGFloat { -((lastIndex.cgFloatValue * containerHeight) + edgeBouncerAmount) }
    private var currentTranslationIsBiggerThanMinAllowed: Bool { isDraggingDown && (offsetY + trHeight) > 0 }
    private var currentTranslationIsBiggerThanMaxAllowed: Bool { abs(offsetY + trHeight) > abs(maxAllowedDraggUp) }
    private var isOverMin: Bool { currentTranslationIsBiggerThanMinAllowed || (isDraggingDown && isTopIndex) }
    private var isOverMax: Bool { isDraggingUp && (draggingIndex >= lastIndex || currentTranslationIsBiggerThanMaxAllowed) }


    public typealias OnItemView = (Item) -> (ItemView)
    public typealias OnSwipe = (Item) -> ()
    var onItemView: OnItemView
    var onSwipe: OnSwipe?

    public var items: [Item]

    public init(
        _ items: [Item],
        containerHeight: CGFloat = 100,
        containerWidth: CGFloat = 346,
        containerCornerRadius: CGFloat = 24,
        edgeBouncerAmount: CGFloat = 10,
        onTouchDownScaleX: CGFloat = 0.95,
        maxScaleDownX: CGFloat = 0.85,
        maxScaleDownY: CGFloat = 0.85,
        percentageToSwipe: CGFloat = 0.02,
        animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2),
        @ViewBuilder _ onItemView: @escaping OnItemView,
        onSwipe: @escaping OnSwipe
    ) {
        self.items = items
        self.containerHeight = containerHeight
        self.containerWidth = containerWidth
        self.containerCornerRadius = containerCornerRadius
        self.edgeBouncerAmount = edgeBouncerAmount
        self.onTouchDownScaleX = onTouchDownScaleX
        self.maxScaleDownX = maxScaleDownX
        self.maxScaleDownY = maxScaleDownY
        self.animation = animation
        self.percentageToSwipe = percentageToSwipe
        self.onItemView = onItemView
        self.onSwipe = onSwipe
    }


    var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                withAnimation(animation) {
                    dragValue = value
                    if isOverMin {
                        draggingIndex = startIndex
                        offsetY = edgeBouncerAmount
                        return
                    }

                    if isOverMax {
                        draggingIndex = lastIndex
                        offsetY = maxAllowedDraggUp
                        return
                    }
                    offsetY += trHeight
                    scaleY = abs(max(maxScaleDownY, (trHeight / 100) - 1))
                    scaleX = abs(max(maxScaleDownX, (trWidth / 100) - 1))
                }
            }
            .onEnded { _ in
                withAnimation(animation) {
                    isDragging = false
                    if isTranslationGreaterThanTenPercent {
                        if isDraggingDown {
                            draggingIndex = isTopIndex ? startIndex : draggingIndex - 1
                        } else if isDraggingUp {
                            draggingIndex = isLastIndex ? lastIndex : draggingIndex + 1
                        }
                    }
                    offsetY = -(draggingIndex.cgFloatValue * containerHeight)
                    onSwipe?(items[draggingIndex])
                }
            }
    }

    var longGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.002)
            .onEnded { _ in
                withAnimation {
                    scaleY = onTouchDownScaleX
                    scaleX = onTouchDownScaleX
                    isDragging = true
                }
            }
    }

    var combinedGesture: some Gesture {
        SequenceGesture(longGesture, drag)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack {
                        onItemView(item)
                    }
                    .frame(width: containerWidth, height: containerHeight)
                    .cornerRadius(containerCornerRadius)
                    .scaleEffect(x: isDragging ? scaleX : 1, y: isDragging ? scaleY : 1, anchor: .center)
                    .offset(CGSize(width: 0, height: offsetY))
                    .gesture(combinedGesture)
                    .onLongPressGesture(minimumDuration: 0.002, maximumDistance: 0) {} onPressingChanged: { isPressing in
                        withAnimation {
                            scaleY = isPressing ? onTouchDownScaleX : 1
                            scaleX = isPressing ? onTouchDownScaleX : 1
                            isDragging = isPressing
                        }
                    }
                }
            }
        }
        .frame(width: containerWidth, height: containerHeight, alignment: .top)
        .cornerRadius(containerCornerRadius)
    }
}

