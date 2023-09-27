//
//  SwipyViewModel.swift
//  Swipy
//
//  Created by hamed on 1/29/23.
//

import Combine
import SwiftUI

public class SwipyViewModel<T: Identifiable>: ObservableObject {
    public typealias Item = T
    public typealias OnSwipe = (Item) -> ()
    public var onSwipe: OnSwipe?

    public let direction: Direction
    public var items: [Item]

    public var offsetValue: CGFloat = 0
    public var containerSize: CGFloat = 72
    public var itemSize: CGFloat = 72
    public var scaleY: CGFloat = 1
    public var scaleX: CGFloat = 1
    public var scale3d: CGFloat = 0
    public var scaleDegree: CGFloat = 0
    public var isDragging = false
    public var draggingIndex: Int = 0
    public var dragValue: DragGesture.Value?
    public var selection: Item.ID?
    public var wasOverDragging: Bool = true
    public var animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2)

    public var edgeBouncerAmount: CGFloat = 10
    public var onTouchDownScaleX: CGFloat = 0.95
    public var maxScaleDownX: CGFloat = 0.85
    public var maxScaleDownY: CGFloat = 0.85
    public var percentageToSwipe: CGFloat = 0.02

    public var isTranslationGreaterThanTenPercent: Bool { abs(trValue) > (containerSize * percentageToSwipe) }
    public var trValue: CGFloat { direction == .horizontal ? dragValue?.translation.width ?? 0 : dragValue?.translation.height ?? 0 }
    public var isTopIndex: Bool { draggingIndex == 0 }
    public var startIndex: Int { items.startIndex }
    public var lastIndex: Int { items.endIndex - 1 }
    public var isLastIndex: Bool { draggingIndex == lastIndex }
    public var isGreaterThanLastIndex: Bool { draggingIndex > lastIndex }
    public var isDraggingEnd: Bool { trValue > 0 }
    public var isDraggingStart: Bool { trValue < 0 }
    public var maxAllowedDraggUp: CGFloat { -((lastIndex.cgFloatValue * containerSize) + edgeBouncerAmount) }
    public var currentTranslationIsBiggerThanMinAllowed: Bool { isDraggingEnd && (offsetValue + trValue) > 0 }
    public var currentTranslationIsBiggerThanMaxAllowed: Bool { abs(offsetValue + trValue) > abs(maxAllowedDraggUp) }
    public var isOverMin: Bool { currentTranslationIsBiggerThanMinAllowed || (isDraggingEnd && isTopIndex) }
    public var isOverMax: Bool { isDraggingStart && (draggingIndex >= lastIndex || currentTranslationIsBiggerThanMaxAllowed) }

    public init(
        direction: Direction,
        _ items: [Item],
        selection: Item.ID? = nil,
        itemSize: CGFloat,
        containerSize: CGFloat,
        edgeBouncerAmount: CGFloat = 10,
        onTouchDownScaleX: CGFloat = 0.95,
        maxScaleDownX: CGFloat = 0.85,
        maxScaleDownY: CGFloat = 0.85,
        percentageToSwipe: CGFloat = 0.02,
        animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2),
        onSwipe: OnSwipe? = nil
    ) {
        self.direction = direction
        self.itemSize = itemSize
        self.containerSize = containerSize
        self.items = items
        self.selection = selection
        self.edgeBouncerAmount = edgeBouncerAmount
        self.onTouchDownScaleX = onTouchDownScaleX
        self.maxScaleDownX = maxScaleDownX
        self.maxScaleDownY = maxScaleDownY
        self.animation = animation
        self.percentageToSwipe = percentageToSwipe
        self.onSwipe = onSwipe
        updateForSelectedItem()
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
        animateObjectWillChange()
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
        animateObjectWillChange()
    }

    func onPrsssingScale() {
        scaleY = onTouchDownScaleX
        scaleX = onTouchDownScaleX
    }

    func onDraggingScale() {
        scaleY = abs(max(maxScaleDownY, (trValue / 100)))
        scaleX = scaleY
    }

    func onResetScale() {
        scaleY = 1
        scaleX = 1
    }

    func onOverDraggingFirstIndex() {
        draggingIndex = startIndex
        offsetValue = edgeBouncerAmount
        onResetScale()
    }

    func onOverDraggingLastIndex() {
        draggingIndex = lastIndex
        offsetValue = maxAllowedDraggUp
        onResetScale()
    }

    func calculateOffsetOnDragging() {
        offsetValue += trValue
    }

    func calculateOffsetForCurrentSelection() {
        offsetValue = -(draggingIndex.cgFloatValue * itemSize)
    }

    func calculateOnFinishedDraggingIndex() {
        if isTranslationGreaterThanTenPercent {
            if isDraggingEnd {
                onDragDownIndex()
            } else if isDraggingStart {
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
        isDragging = false
        calculateOnFinishedDraggingIndex()
        calculateOffsetForCurrentSelection()
        selection = items[draggingIndex].id
        onSwipe?(items[draggingIndex])
        scale3d = 0
        animateObjectWillChange()
    }

    public func updateForSelectedItem() {
        if let selection = selection, let selectedIndex = items.firstIndex(where: {$0.id == selection }) {
            draggingIndex = selectedIndex
            isDragging = false
            calculateOnFinishedDraggingIndex()
            calculateOffsetForCurrentSelection()
            onSwipe?(items[draggingIndex])
            scale3d = 0
            animateObjectWillChange()
        }
    }

    func onSelection(_ selection: Item.ID?) {
        if selection == self.selection { return }
        withAnimation {
            if let selection = selection, let selectedIndex = items.firstIndex(where: {$0.id == selection }) {
                draggingIndex = selectedIndex
                calculateOffsetForCurrentSelection()
                onResetScale()
            }
        }
        animateObjectWillChange()
    }

    var debudDescription: String {
        let dic: [String: Any] = [
            "offsetValue": offsetValue,
            "scaleY": scaleY,
            "scaleX": scaleX,
            "isDragging": isDragging,
            "draggingIndex": draggingIndex,
            "dragValue": dragValue.debugDescription,
            "isTranslationGreaterThanTenPercent": isTranslationGreaterThanTenPercent,
            "trValue": trValue,
            "isTopIndex": isTopIndex,
            "startIndex": startIndex,
            "lastIndex": lastIndex,
            "isLastIndex": isLastIndex,
            "isGreaterThanLastIndex": isGreaterThanLastIndex,
            "isDraggingEnd": isDraggingEnd,
            "isDraggingStart": isDraggingStart,
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
            "containerSize": containerSize
        ]
        return dic.map{"\($0): \($1)"}.joined(separator: ",\n")
    }

    func animateObjectWillChange() {
        withAnimation {
            objectWillChange.send()
        }
    }
}

public enum Direction {
    case horizontal
    case vertical
}

public class HSwipyViewModel<T: Identifiable>: SwipyViewModel<T> {
    public init(_ items: [SwipyViewModel<T>.Item],
                         selection: SwipyViewModel<T>.Item.ID? = nil,
                         itemSize: CGFloat,
                         containerSize: CGFloat,
                         edgeBouncerAmount: CGFloat = 10,
                         onTouchDownScaleX: CGFloat = 0.95,
                         maxScaleDownX: CGFloat = 0.85,
                         maxScaleDownY: CGFloat = 0.85,
                         percentageToSwipe: CGFloat = 0.02,
                         animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2),
                         onSwipe: SwipyViewModel<T>.OnSwipe? = nil) {
        super.init(direction: .horizontal,
                   items,
                   selection: selection,
                   itemSize: itemSize,
                   containerSize: containerSize,
                   edgeBouncerAmount: edgeBouncerAmount,
                   onTouchDownScaleX: onTouchDownScaleX,
                   maxScaleDownX: maxScaleDownX,
                   maxScaleDownY: maxScaleDownY,
                   percentageToSwipe: percentageToSwipe,
                   animation: animation,
                   onSwipe: onSwipe)
    }
}

public class VSwipyViewModel<T: Identifiable>: SwipyViewModel<T> {
    public init(_ items: [SwipyViewModel<T>.Item],
                selection: SwipyViewModel<T>.Item.ID? = nil,
                itemSize: CGFloat,
                containerSize: CGFloat,
                edgeBouncerAmount: CGFloat = 10,
                onTouchDownScaleX: CGFloat = 0.95,
                maxScaleDownX: CGFloat = 0.85,
                maxScaleDownY: CGFloat = 0.85,
                percentageToSwipe: CGFloat = 0.02,
                animation: Animation = .interactiveSpring(response: 0.1, dampingFraction: 0.5).speed(0.2),
                onSwipe: SwipyViewModel<T>.OnSwipe? = nil) {
        super.init(direction: .vertical,
                   items,
                   selection: selection,
                   itemSize: itemSize,
                   containerSize: containerSize,
                   edgeBouncerAmount: edgeBouncerAmount,
                   onTouchDownScaleX: onTouchDownScaleX,
                   maxScaleDownX: maxScaleDownX,
                   maxScaleDownY: maxScaleDownY,
                   percentageToSwipe: percentageToSwipe,
                   animation: animation,
                   onSwipe: onSwipe)
    }
}
