//
//  HSwipy.swift
//  Swipy
//
//  Created by hamed on 1/29/23.
//

import SwiftUI
import Combine

public struct HSwipy<T: Identifiable, ItemView: View>: View, SwipyProtocol {
    public typealias Item = T

    public var edgeBouncerAmount: CGFloat = 10
    public var onTouchDownScaleX: CGFloat = 0.95
    public var maxScaleDownX: CGFloat = 0.85
    public var maxScaleDownY: CGFloat = 0.85
    public var percentageToSwipe: CGFloat = 0.02
    public var animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2)

    @State private var containerWidth: CGFloat = 346
    @State private var offsetX: CGFloat = .zero
    @State private var scaleY: CGFloat = 1
    @State private var scaleX: CGFloat = 1
    @State public var scale3d: CGFloat = 0
    @State public var scaleDegree: CGFloat = 0
    @State private var isDragging = false
    @State private var draggingIndex: Int = 0
    @State private var dragValue: DragGesture.Value?
    @Binding var selection: Item.ID?
    @State public var isOpenMode: Bool = false
    @State private var wasOverDragging: Bool = true


    private var isTranslationGreaterThanTenPercent: Bool { abs(trWidth) > (containerWidth * percentageToSwipe) }
    private var trHeight: CGFloat { dragValue?.translation.height ?? 0 }
    private var trWidth: CGFloat { dragValue?.translation.width ?? 0 }
    private var isTopIndex: Bool { draggingIndex == 0 }
    private var startIndex: Int { items.startIndex }
    private var lastIndex: Int { items.endIndex - 1 }
    private var isLastIndex: Bool { draggingIndex == lastIndex }
    private var isGreaterThanLastIndex: Bool { draggingIndex > lastIndex }
    private var isDraggingLeft: Bool { dragValue?.translation.width ?? 0 > 0 }
    private var isDraggingRight: Bool { dragValue?.translation.width ?? 0 < 0 }
    private var maxAllowedDraggUp: CGFloat { -((lastIndex.cgFloatValue * containerWidth) + edgeBouncerAmount) }
    private var currentTranslationIsBiggerThanMinAllowed: Bool { isDraggingLeft && (offsetX + trWidth) > 0 }
    private var currentTranslationIsBiggerThanMaxAllowed: Bool { abs(offsetX + trWidth) > abs(maxAllowedDraggUp) }
    private var isOverMin: Bool { currentTranslationIsBiggerThanMinAllowed || (isDraggingLeft && isTopIndex) }
    private var isOverMax: Bool { isDraggingRight && (draggingIndex >= lastIndex || currentTranslationIsBiggerThanMaxAllowed) }


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
            .onEnded { _ in
                onLongPressing(true)
            }
    }

    var combinedGesture: some Gesture {
        SequenceGesture(longGesture, drag)
    }

    public var body: some View {
        GeometryReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(items) { item in
                        onItemView(item)
                        .frame(width: containerWidth)
                        .scaleEffect(x: isDragging ? scaleX : 1, y: isDragging ? scaleY : 1, anchor: .center)
                        .offset(CGSize(width: offsetX, height: 0))
                        .gesture(combinedGesture)
                        .onLongPressGesture(minimumDuration: 0.002, maximumDistance: 0) {} onPressingChanged: { isPressing in
                            onLongPressing(isPressing)
                        }
                    }
                }
            }
            .onAppear {
                containerWidth = reader.size.width
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

        withAnimation(.easeInOut) {
            scale3d = isPressing ? 1 : 0
            scaleDegree = isPressing ? 32 : 0
        }
    }

    func onPrsssingScale() {
        scaleY = onTouchDownScaleX
        scaleX = onTouchDownScaleX
    }

    func onDraggingScale() {
        scaleY = abs(max(maxScaleDownY, (trWidth / 100)))
        scaleX = scaleY
    }

    func onResetScale() {
        scaleY = 1
        scaleX = 1
    }

    func onDragging() {
        if wasOverDragging {
            return
        }
        withAnimation(animation) {
            if isOverMin {
                wasOverDragging = true
                onOverDraggingFirstIndex()
                return
            }

            if isOverMax {
                wasOverDragging = true
                onOverDraggingLastIndex()
                return
            }
            if wasOverDragging {
                wasOverDragging = false
            }
            calculateOffsetOnDragging()
            onDraggingScale()
        }
    }

    func onOverDraggingFirstIndex() {
        draggingIndex = startIndex
        offsetX = edgeBouncerAmount
        onResetScale()
    }

    func onOverDraggingLastIndex() {
        draggingIndex = lastIndex
        offsetX = maxAllowedDraggUp
        onResetScale()
    }

    func calculateOffsetOnDragging() {
        offsetX += trWidth
    }

    func calculateOffsetForCurrentSelection() {
        offsetX = -(draggingIndex.cgFloatValue * containerWidth)
    }

    func calculateOnFinishedDraggingIndex() {
        if isTranslationGreaterThanTenPercent {
            if isDraggingLeft {
                onDragLeftIndex()
            } else if isDraggingRight {
                onDragRightIndex()
            }
        }
        onResetScale()
    }

    func onDragLeftIndex() {
        draggingIndex = isTopIndex ? startIndex : draggingIndex - 1
    }

    func onDragRightIndex() {
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

        withAnimation {
            scale3d = 0
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
            "offsetX": offsetX,
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
            "isDraggingLeft": isDraggingLeft,
            "isDraggingRight": isDraggingRight,
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
            "animation": animation,
            "containerWidth": containerWidth
        ]
        return dic.map{"\($0): \($1)"}.joined(separator: ",")
    }
}

