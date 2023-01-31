//
//  VSwipy.swift
//  Swipy
//
//  Created by hamed on 1/29/23.
//

import SwiftUI
import Combine

public struct VSwipy<T: Identifiable, ItemView: View>: View, SwipyProtocol {
    public typealias Item = T

    public var edgeBouncerAmount: CGFloat = 10
    public var onTouchDownScaleX: CGFloat = 0.95
    public var maxScaleDownX: CGFloat = 0.85
    public var maxScaleDownY: CGFloat = 0.85
    public var percentageToSwipe: CGFloat = 0.02
    public var animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2)

    @State private var containerHeight: CGFloat = 100
    @State private var offsetY: CGFloat = .zero
    @State private var scaleY: CGFloat = 1
    @State private var scaleX: CGFloat = 1
    @State private var isDragging = false
    @State private var draggingIndex: Int = 0
    @State private var dragValue: DragGesture.Value?
    @Binding var selection: Item.ID?


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
        selection: Binding<Item.ID?>? = nil,
        edgeBouncerAmount: CGFloat = 10,
        onTouchDownScaleX: CGFloat = 0.95,
        maxScaleDownX: CGFloat = 0.85,
        maxScaleDownY: CGFloat = 0.85,
        percentageToSwipe: CGFloat = 0.02,
        animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2),
        @ViewBuilder _ onItemView: @escaping OnItemView,
        onSwipe: OnSwipe? = nil
    ) {
        self.items = items
        self._selection = selection ?? Binding.constant(nil)
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
                dragValue = value
                onDragging()
            }
            .onEnded { _ in
                onDrageFinished()
            }
    }

    var longGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.002)
            .onEnded { finished in
                onLongPressing(true)
            }
    }

    var combinedGesture: some Gesture {
        SequenceGesture(longGesture, drag)
    }

    public var body: some View {
        GeometryReader { reader in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        onItemView(item)
                            .frame(height: containerHeight)
                            .scaleEffect(x: isDragging ? scaleX : 1, y: isDragging ? scaleY : 1)
                            .offset(CGSize(width: 0, height: offsetY))
                            .gesture(combinedGesture)
                            .onLongPressGesture(minimumDuration: 0.002, maximumDistance: 0) {} onPressingChanged: { isPressing in
                                onLongPressing(isPressing)
                            }
                    }
                }
            }
            .onAppear {
                containerHeight = reader.size.height
            }
            .onReceive(Just(selection)) { newValue in
                onSelection(newValue)
            }
        }
    }

    func onLongPressing(_ isPressing: Bool) {
        withAnimation {
            isDragging = isPressing
            if isPressing {
                onPrsssingScale()
            } else {
                onResetScale()
            }
        }
    }

    func onPrsssingScale() {
        scaleY = onTouchDownScaleX
        scaleX = onTouchDownScaleX
    }

    func onDraggingScale() {
        scaleY = abs(max(maxScaleDownY, (trHeight / 100)))
        scaleX = scaleY
    }

    func onResetScale() {
        scaleY = 1
        scaleX = 1
    }

    func onDragging() {
        withAnimation(animation) {
            if isOverMin {
                onOverDraggingFirstIndex()
                return
            }

            if isOverMax {
                onOverDraggingLastIndex()
                return
            }
            calculateOffsetOnDragging()
            onDraggingScale()
        }
    }

    func onOverDraggingFirstIndex() {
        draggingIndex = startIndex
        offsetY = edgeBouncerAmount
        onResetScale()
    }

    func onOverDraggingLastIndex() {
        draggingIndex = lastIndex
        offsetY = maxAllowedDraggUp
        onResetScale()
    }

    func calculateOffsetOnDragging() {
        offsetY += trHeight
    }

    func calculateOffsetForCurrentSelection() {
        offsetY = -(draggingIndex.cgFloatValue * containerHeight)
    }

    func calculateOnFinishedDraggingIndex() {
        if isTranslationGreaterThanTenPercent {
            if isDraggingDown {
                onDragDownIndex()
            } else if isDraggingUp {
                onDragUpIndex()
            }
        }
        onResetScale()
    }

    func onDragDownIndex() {
        draggingIndex = isTopIndex ? startIndex : draggingIndex - 1
    }

    func onDragUpIndex() {
        draggingIndex = isLastIndex ? lastIndex : draggingIndex + 1
    }

    func onDrageFinished() {
        withAnimation(animation) {
            isDragging = false
            calculateOnFinishedDraggingIndex()
            calculateOffsetForCurrentSelection()
            selection = items[draggingIndex].id
            onSwipe?(items[draggingIndex])
        }
    }

    func onSelection(_ selection: Item.ID?) {
        withAnimation {
            if let selection = selection, let selectedIndex = items.firstIndex(where: {$0.id == selection }) {
                draggingIndex = selectedIndex
                calculateOffsetForCurrentSelection()
                onResetScale()
            }
        }
    }

    var debudDescription: String {
        let dic: [String: Any] = [
            "offsetY": offsetY,
            "scaleY": scaleY,
            "scaleX": scaleX,
            "isDragging": isDragging,
            "draggingIndex": draggingIndex,
            "dragValue": dragValue.debugDescription,
            "isTranslationGreaterThanTenPercent": isTranslationGreaterThanTenPercent,
            "trHeight": trHeight,
            "trWidth": trWidth,
            "isTopIndex": isTopIndex,
            "startIndex": startIndex,
            "lastIndex": lastIndex,
            "isLastIndex": isLastIndex,
            "isGreaterThanLastIndex": isGreaterThanLastIndex,
            "isDraggingDown": isDraggingDown,
            "isDraggingUp": isDraggingUp,
            "maxAllowedDraggUp": maxAllowedDraggUp,
            "currentTranslationIsBiggerThanMinAllowed": currentTranslationIsBiggerThanMinAllowed,
            "currentTranslationIsBiggerThanMaxAllowed": currentTranslationIsBiggerThanMaxAllowed,
            "isOverMin": isOverMin,
            "isOverMax": isOverMax,
            "edgeBouncerAmount": edgeBouncerAmount,
            "onTouchDownScaleX": onTouchDownScaleX,
            "maxScaleDownX": maxScaleDownX,
            "maxScaleDownY": maxScaleDownY,
            "percentageToSwipe": percentageToSwipe,
            "containerHeight": containerHeight
        ]
        return dic.map{"\($0): \($1)"}.joined(separator: ",\n")
    }
}

