//
//  PanExample.swift
//  Gestures
//
//  Created by David James on 2021-12-09.
//

import C3
import Unilib
import Combine

// Device: Any device
// Video: https://a.cl.ly/7KuqojOg
// Test: visual match, follow pan gestures of video with matching behaviour
// Test: orientation changes, light and dark mode (optional)

// Repository: https://github.com/davidbjames/Gestures

class PanView : View, Live, Themeable {
    private lazy var insets:InsetGroup = 10.0...50.0
    private lazy var spacing:OffsetPair = 3.0...17.0
    func live(update: Update) {
        onCreate { $0
            .applyTheme()
        }
        onRequiredUpdateMake {
            // LEARNING: This is a good example of using definable areas,
            // safe area guides and insets. A lot going on here.
            // See also below that incorporates concentric corners in definable areas.
            View(insets:insets, options:.safeArea)
                .in($0, options:.reusable, repeat:5)
                .referenceSafeArea(minInsets:insets)
                .spread(update.isPortrait ? .vertical : .horizontal, spacing:spacing)
                .applyTheme()
                .make(.zipped) {
                    OutOfParentExample()
                        .in($0)
                    IntoParentExample()
                        .in($0)
                    IntoSingleItemExample()
                        .in($0)
                    IntoMultipleItemsExample()
                        .in($0)
                    OverMultipleItemsExample()
                        .in($0)
                }
        }
    }
    var implicitAnimation: ImplicitAnimationConfig? = .disabled
    class OutOfParentExample : Example {
        class MyPanGesture : PanGestureRecognizer {}
        lazy var panUpdates:Passthrough<MyPanGesture> = .init()
        override func live(update: Update) {
            super.live(update:update)
            onRequiredUpdateMake {
                let threshold:Number = update.isPortrait ? 60% : 80%
                Parent(insets:Theme.defaults.insets, options:.concentric)
                    .in($0)
                    .applyTheme()
                    .unflatten() // keep border under pannable view's border
                    .build {
                        PannableView(options:.concentric)
                            .in($0)
                            // TBD: Attempt to eliminate problems animating
                            // shape-based borders on orientation change.
                            // May need to disable other places or provide
                            // a general solution on orientation changes?
                            // .disableAnimations
                            .applyTheme()
                            .make {
                                Layer()
                                    .id("grabber")
                                    .in($0, options:.reusable, repeat:2)
                                    .inheritCorners()
                                    .first { $0
                                        .fit(area: update.isPortrait ? .leading(20%) : .bottom(20%))
                                    }
                                    .second { $0
                                        .alphaToggle(update.isPortrait)
                                        .fit(area: update.isPortrait ? .trailing(20%) : .top(20%))
                                    }
                                    .applyTheme()
                                Arrow(number:2)
                                    .in($0)
                                    .with { $0.shapes }
                                    .onPortrait {
                                        $0.show()
                                    } else: {
                                        $0.select(ordinal:1).hide()
                                    }
                            }
                    }
                    //.console
                    .onPan { [self] in $0
                        // Example using injected pipeline to relay gesture elsewhere.
                        // Injected pipeline can be used for other reactive integration.
                        .send(to:panUpdates)
                        // Example using vv custom gesture recognizer subclass.
                    } action: { (pan:MyPanGesture, view) in
                        switch pan.state {
                        case .began :
                            break
                            // Stop running animations is an attempt to support
                            // "stutter" interaction where the user lifts their
                            // finger than places it immediately back down.
                            // In theory they should be able to continue from
                            // that point, but this doesn't make any noticable difference
                            // mutator.stopAllAnimations()
                        case .changed :
                            guard pan.completionStatusHasChanged else { return }
                            view
                                .selected(pan.isPastThreshold)
                        case .ended :
                            guard let edge = pan.finalRelativeEdge else { return }
                            view
                                .selected(false)
                                .animateConsecutively()
                                .animate(for:pan.finishingDuration()) { $0
                                    .if (pan.shouldComplete) { $0
                                        .align(edge.opposing, withAnchor:edge)
                                    } else: { $0
                                        .refit()
                                    }
                                }
                                .if (pan.shouldComplete) { $0
                                    .wait(for:1.0)
                                    .animate { $0
                                        .refit()
                                    }
                                }
                                .commit()
                        default :
                            break
                        }
                    }
                    .direction(update.isPortrait ? .horizontal : .up)
                    .threshold(threshold)
                    .addGrabber {
                        $0.with(update.isPortrait ? 2 : 1) { $0.identifiable(Layer.self, id:"grabber") }
                    }
                    .subscribe(.restartable) // to change direction on orientation change
                
                // Debug threshold line.
                Line(axis:update.orientation.axis)
                    .in($0, options:.reusable, repeat:2)
                    .center()
                    .applyTheme()
                    .show()
                    .onReceive(
                        panUpdates
                            .compactMap { $0.probableDirection }
                            .removeDuplicates()
                    ) { $1
                        .guard(update.isPortrait)?
                        .switch($0, [
                            .left : { $0.first { $0.hide() }.second { $0.show() } },
                            .right : { $0.first { $0.show() }.second { $0.hide() } }
                        ])
                    }
                    .reference { $0.previous(Parent.self) }
                    .first { $0
                        .onPortrait { $0
                            .x(threshold)
                        } else: { $0
                            .y(threshold.invertPercentage())
                        }
                    }
                    .second { $0
                        .onPortrait { $0
                            .x(threshold.invertPercentage())
                        } else: { $0
                            .hide() // landscape doesn't need this line
                            .y(threshold)
                        }
                    }
                // "Touch" indicator, if adding visual debug to gestures.
                /*
                Circle()
                    .in($0, options:.reusable)
                    .span(20%)
                    .color(Color.purple.a400)
                    .border(width:5.0, color:Color.purple.s800.alpha(0.6))
                    .alpha(0.0)
                    .make {
                        Circle(span:5.0)
                            .in($0, options:.reusable)
                            .color(Color.purple.s800)
                            .center()
                    }
                */
            }
        }
    }
    class IntoParentExample : Example {
        override func live(update: Update) {
            super.live(update:update)
            guard update.isRequiredUpdate else { return }
            Parent(insets:Theme.defaults.insets, options:.concentric)
                .in(self, repeat:3)
                // LEARNING: To achieve items of diverse sizes that are
                // spread to fit within a containing area:
                // 1. set sizes (aprox.)
                .zip(Array<Number>([10%, 30%, 60%])) {
                    $0.mutate.size($1, on:update.orientation.axis.crossAxis)
                }
                // 2. pin with insets
                .pin(to:update.isPortrait ? .leading : .bottom, insets:Theme.defaults.insets)
                // 3. link with offsets
                .link(update.orientation.axis.crossAxis, offset:-40.0...(-20.0), inverse:update.isLandscape)
                .zPositionAssign(by:-1)
                .applyTheme()
                .last
                // 4. flex pin the last one (with insets)
                .mutate(.flex)
                .pin(to:update.isPortrait ? .trailing : .top, insets:Theme.defaults.insets)
                // Future TODO, understand and abstract this layout relationship
                // It's like "spread" with diverse sizes, where one of those is
                // stretched to fit remaining space. Also related to link and disperse.
                // Keep in mind how this relates to intrinsic content sizes such
                // as images and text (see also UIStackView or SwiftUI equivalents).
            PannableView(insets:Theme.defaults.insets, options:.concentric)
                .in(self)
                .reference { $0.previous(Parent.self, ordinal:0) }
                .pin(to:update.isPortrait ? .trailing : .top, insets:Theme.defaults.insets *? 2.0)
                .applyTheme()
                .make {
                    Layer()
                        .id("grabber")
                        .in($0, options:.reusable)
                        .fit(area:update.isPortrait ? .trailing(5%) : .top(5%))
                        .applyTheme()
                    Arrow(number:1, size:10%)
                        .in($0)
                        .with { $0.shapes }
                        .pin(to:update.isPortrait ? .trailing : .top, insets:Theme.defaults.insets)
                }
                .noReference()
                .onPan { pan, view in
                    switch pan.state {
                    case .began :
                        break
                    case .changed :
                        guard pan.completionStatusHasChanged else { break }
                        view
                            .selected(pan.isProgressing)
                            .updateArrowDirection(pan.isProgressing)
                    case .ended :
                        guard
                            // Since the targets overlap, there will always be
                            // a target ordinal, so just need to decide if to
                            // align to that target (on complete), the one before
                            // it (should not complete), or the first one.
                            let ordinal = pan.targetOrdinal.map({
                                pan.shouldComplete ? $0 : ($0 == 0 ? 0 : $0 - 1)
                            }),
                            let edge = pan.finalRelativeEdge
                        else { return }
                        view
                            .reference { $0.previous(Parent.self, ordinal:ordinal) }
                            .spring(energy:.normal) { $0
                                .align(edge)
                                .selected(false)
                                .updateArrowDirection()
                            }
                            .commit()
                    default :
                        break
                    }
                }
                .direction(update.isPortrait ? .right : .up)
                .addGrabber {
                    $0.with { $0.identifiable(Layer.self, id:"grabber" ) }
                }
                .addLimiter {
                    Layer()
                        .in($0.parent, options:.reusable)
                        // LEARNING: compare pinBetween() to similar implementation
                        // without (see next "addLimiter" below). The number
                        // of lines is about the same, but the important difference
                        // is that pinBetween() provides a logical set of parameters
                        // to walk through, whereas the manual approach (below) provides
                        // no such path to follow, and is therefore quite tricky
                        // to implement, even with experience.
                        .pinBetween(
                            edges: .outer,
                            axis: update.orientation.axis.crossAxis,
                            inverted: update.isLandscape,
                            between: {
                                $0.previous(PannableView.self)
                            },
                            and: {
                                $0.previous(Parent.self, ordinal:2)
                            }
                        )
                        .q
                }
                .addTargets {
                    $0.inScope.views(Parent.self)
                }
                .subscribe(.restartable)
        }
    }
    class IntoSingleItemExample : Example {
        override func live(update: Update) {
            super.live(update:update)
            onRequiredUpdateMake {
                let threshold:Number = 70%
                Parent(area:update.isPortrait ? .trailing(30%) : .top(30%), insets:Theme.defaults.insets, options:.concentric)
                    .ordinal(1)
                    .in($0)
                    .applyTheme()
                Parent(area:update.isPortrait ? .leading(30%) : .bottom(30%), insets:Theme.defaults.insets, options:.concentric)
                    .ordinal(0)
                    .in($0)
                    .applyTheme()
                    .build {
                        PannableView()
                            .in($0)
                            .inheritCorners() // not concentric
                            .size(50%, on:update.orientation.axis, matchCrossAxis:true)
                            .center()
                            .applyTheme()
                            .make {
                                Arrow()
                                    .in($0)
                            }
                    }
                    .reference { $0.previous(Parent.self, ordinal:1) }
                    .onPan { pan, view in
                        switch pan.state {
                        case .began :
                            break
                        case .changed :
                            break
                        case .ended :
                            let duration = pan.finishingDuration()
                            view
                                .animateConsecutively()
                                .animate(for:duration) { $0
                                    .if (pan.shouldComplete) { $0
                                        .reference { $0.previous(Parent.self, ordinal:1) }
                                        .center()
                                    } else: { $0
                                        .center()
                                    }
                                }
                                .if (pan.shouldComplete) { $0
                                    .wait(for:1.0)
                                    .animate { $0
                                        .center()
                                    }
                                }
                                .commit()
                        default :
                            break
                        }
                    }
                    .direction(update.isPortrait ? .right : .up)
                    .threshold(threshold)
                    .addLimiter { view in
                        Layer()
                            .in(view.parent, options:.reusable)
                            .reference(view)
                            .align(position:update.isPortrait ? .topLeading : .bottomLeading)
                            .sizeToReference(axis:update.orientation.axis)
                            .mutate(.flex)
                            .reference { $0.previous(Parent.self, ordinal:1) }
                            .align(update.isPortrait ? .trailing : .top)
                            .q
                    }
                    .subscribe(.restartable)
                
                /*
                Example: updating "spacer" guide.
                Ended up creating referenceBetween() operator instead
                which accomplishes the same vvv.
                 
                onRequiredUpdateMake {
                    Guide()
                        .in($0, options:.reusable)
                        .reference(PannableView.self)
                        .align(update.isPortrait ? .leading : .bottom)
                        .reference(Parent.self, ordinal:1)
                        .align(
                            update.isPortrait ? .trailing : .top,
                            withAnchor: update.isPortrait ? .leading : .bottom
                        )
                        .debugOverlay()
                }
                */
                
                Line(axis:update.orientation.axis)
                    .in($0, options:.reusable)
                    // .reference { $0.previous(Guide.self) }
                    .referenceBetween(
                        edges: .min,
                        axis: update.orientation.axis.crossAxis,
                        inverted: update.isLandscape,
                        between: {
                            $0.firstInScope.views(PannableView.self)
                        },
                        and: {
                            $0.previous(Parent.self, ordinal:1)
                        }
                    )
                    .applyTheme()
                    .onPortrait { $0
                        .x(threshold)
                        .centerVertically()
                    } else: { $0
                        .y(threshold.invertPercentage())
                        .centerHorizontally()
                    }
            }
        }
    }
    class IntoMultipleItemsExample : Example {
        override func live(update: Update) {
            super.live(update:update)
            onRequiredUpdateMake {
                let layout:(Mutator<IntoMultipleItemsExample,Parent>)->Void = { $0
                    // LEARNING: when capturing closure for reuse that references
                    // context values (orientation etc) you must pull from the
                    // current context on the object (or ContextView) and not
                    // just rely on the captured update which will not remain
                    // accurate.
                    .first { $0
                        .context(\.isPortrait) { $0
                            .pin(to:$1 ? .leading : .bottom, insets:Theme.defaults.insets)
                        }
                    }
                    .afterFirst { $0
                        .context(\.orientation) { $0
                            .pin(to:$1.isPortrait ? .trailing : .top, insets:Theme.defaults.insets)
                            .link($1.axis.crossAxis, offset:Theme.defaults.offsets, inverse:$1.isPortrait)
                        }
                    }
                    .onLandscape { $0
                        .at([0,1]) { $0.trailing(Theme.defaults.insets.trailing) }
                        .at(2) { $0.leading(Theme.defaults.insets.leading) }
                    }
                }
                let parents = Parent(insets:Theme.defaults.insets, options:.concentric)
                    .in($0, repeat:3)
                    .size(22%, on:update.orientation.axis.crossAxis)
                    .onLandscape { $0
                        // because smaller arrows on landscape, sync with arrow size below
                        .size(60%, on:update.orientation.axis)
                    }
                    .aside(layout)
                    .applyTheme()
                    .make {
                        TextLayer()
                            .in($0, options:.reusable)
                            .textFromOrdinal()
                            .applyThemeAndFit()
                            .center()
                    }
                    // Example storing query items weakly.
                    // See onPan closure "strongify".
                    .weakify
                PannableView()
                    .in($0)
                    .inheritCorners() // not concentric
                    .zPosition(2.0)
                    .size(50%, on:update.orientation.axis, matchCrossAxis:true)
                    .referenceBetween(
                        edges: .inner,
                        axis: update.orientation.axis.crossAxis,
                        between: {
                            $0.previous(Parent.self, ordinal:0)
                        },
                        and: {
                            $0.previous(Parent.self, ordinal:2)
                        }
                    )
                    .center()
                    .applyTheme()
                    .make {
                        Arrow(
                            number: update.isPortrait ? 2 : 4,
                            size: 20%
                        )
                        .in($0)
                        .with { $0.shapes }
                        .onPortrait {
                            $0.select(ordinal:2,3).hide()
                        } else: {
                            $0.show()
                        }
                    }
                    //.console
                    .onPan { pan, view in
                        switch pan.state {
                        case .began :
                            break
                        case .changed :
                            parents
                                // Example restoring query items strongly.
                                .strongify?
                                .animate { $0
                                    .resetTransform()
                                    .alpha(0.6)
                                    .ifLet (pan.targetOrdinal) { $0
                                        .select(ordinal:$1) { $0
                                            .alpha(1.0)
                                            .context(\.orientation) { $0
                                                .scaleBy(
                                                    x: 1.15,
                                                    y: $1.isPortrait ? 1.0 : 1.15,
                                                    replacing:true
                                                )
                                            }
                                        }
                                    }
                                    .mutate(includeTransforms:true)
                                    .aside(layout)
                                }
                                .commit()
                        case .ended :
                            parents
                                .strongify?
                                .animate { $0
                                    .resetTransform()
                                    .alpha(1.0)
                                    .mutate
                                    .aside(layout)
                                }
                                .commit()
                            if let ordinal = pan.targetOrdinal, pan.shouldComplete {
                                view
                                    .reference { $0.previous(Parent.self, ordinal:ordinal) }
                                    .animate { $0
                                        .center()
                                    }
                                    .commit()
                            } else {
                                view
                                    .referenceBetween
                                    .animate { $0
                                        .center()
                                    }
                                    .commit()
                            }
                        default :
                            break
                        }
                    }
                    .if (update.isPortrait) { $0.direction(.horizontal) }
                    .addTargets {
                        $0.inScope.views(Parent.self)
                    }
                    .addLimiter {
                        $0.parent(Example.self)
                    }
                    .subscribe(.restartable)
            }
        }
    }
    class OverMultipleItemsExample : Example {
        var currentOrder:[Int] = []
        override func live(update: Update) {
            super.live(update:update)
            let offset:OffsetPair = Theme.defaults.offsets *? 2.0
            let alignment:Layout.Position = update.isPortrait ? .topLeadingOffset(offset) : .topTrailingOffset(.init(x:offset.negated.x, y:offset.y))
            let flowProgression:Layout.FlowProgression = update.isPortrait ? .forwardThenDownward : .downwardThenBackward
            let layout:(Mutator<OverMultipleItemsExample,PannableView>)->Void = { $0
                .onUpdateNarrow {
                    // LEARNING: "ordered(by:)" assumptions.
                    // It assumes the items start in original order
                    // (e.g. with consecutive ordinals) before reordering.
                    $0.orderedBy(ordinals:self.currentOrder)
                }!
                .reference { $0.parent }
                .onPortrait { $0
                    .align(position:alignment)
                    .flow(flowProgression, spacing:offset, insets:offset.toInsetGroup, edge:.max, secondEdge:.max, alignment:.justified(lastLine:.justified))
                } else: { $0
                    .center()
                    .emanateGroup(by:7, on:.height, offset:offset) { i, item in
                        switch i {
                        case 0, 7 : return 0
                        case 1, 8 : return 1
                        case 2, 9 : return 2
                        case 3, 10 : return 3
                        case 4, 11 : return 4
                        case 5, 12 : return 5
                        case 6 : return IndexedAlignment(from:6, on:.center(.horizontal), to:5, with:nil, offset:nil)
                        default : preconditionFailure()
                        }
                    }
                }
            }
            onRequiredUpdateBuild {
                
                Parent(insets:Theme.defaults.insets, options:.concentric)
                    .in($0)
                    .applyTheme()
                    .build {
                        PannableView()
                            .in($0, repeat:13)
                            .inheritCorners()
                            .size(32%, on:update.orientation.axis, matchCrossAxis:true)
                            .aside(layout)
                            .applyTheme()
                            .make {
                                // LEARNING: make/build blocks are not loops (given
                                // we are in a query of multiple pannable items).
                                // There is only the one "prototype" Arrow instance
                                // created here, with a custom initialization value.
                                // On attachment (in($0)) the Arrow instance is cloned
                                // (after the first) so you must override clone() on
                                // the Arrow class in order to copy over the custom value.
                                // Arrow(number:4, size:10%, offset:[-20.0...(-10.0),0.0])
                                //     .in($0)
                                TextLayer()
                                    .in($0, options:.reusable)
                                    .textFromOrdinal()
                                    .applyThemeAndFit()
                                    .center()
                            }
                            .onCreate { // capture initial order
                                self.currentOrder = $0.items.compactMap { $0.index }
                            }
                    }
            }
            // Since multi-pans use snapshots which are created
            // after rendering, make sure to defer the creation
            // of the gesture itself.
            .onRequiredUpdateDefer(0.5) { $0
                
                .onMultiPan { [self] pan, views in
                    
                    switch pan.state {
                    case .began :
                        break
                    case .changed :
                        guard
                            pan.targetHasChanged,
                            let ordinal = pan.ordinal,
                            let targetOrdinal = pan.targetOrdinal
                        else { return }
                        currentOrder = currentOrder.move(ordinal, after:targetOrdinal)
                        views
                            .animate { $0
                                .aside(layout)
                                .resetTransform()
                                .select(ordinal:targetOrdinal)
                                .scale(by:1.2)
                            }
                            .commit()
                    case .ended :
                        views
                            .animate { $0
                                .resetTransform()
                            }
                            .commit()
                    default :
                        break
                    }
                } snapshot: { pan, snapshot in
                    switch pan.state {
                    case .began :
                        break
                    case .changed :
                        guard pan.targetHasChanged && pan.targetOrdinal.exists else { return }
                        // Spin item whenever it cross over another item
                        // snapshot.animate { $0.turn() }.commit()
                    case .ended :
                        // Remember that synchronization of snapshots' positions
                        // has already occured at this point, so any further
                        // position changes here will mess that up.
                        break
                    default :
                        break
                    }
                }
                .addLimiter {
                    $0.parent
                }
                .subscribe(.restartable)
            }
        }
    }
    class Example : View, Live {
        func live(update: Update) {
            onRequiredUpdate { $0
                .applyTheme()
            }
        }
    }
    class Parent : View, Live {
        func live(update: Update) {
            //mutate.debugRuler(.grid)
        }
    }
    class PannableView : View, Live, AdhocControl {
        func live(update: Update) {
            //mutate.debugRuler()
        }
    }
    class Arrow : Layer, Live {
        var number:Int = 1
        var size:Number = 20%
        var offset:OffsetPair?
        init(number:Int = 1, size:Number = 20%, offset:OffsetPair? = nil) {
            self.number = number
            self.size = size
            self.offset = offset ?? (number == 4 ? [-4.0...(-2.0), 17.0...34.0] : Theme.defaults.offsets)
            super.init()
        }
        override func clone(from original: AnyObject, cheaply: Bool) {
            super.clone(from:original, cheaply:cheaply)
            guard let arrow = original as? Arrow else { return }
            self.number = arrow.number
            self.size = arrow.size
            self.offset = arrow.offset
        }
        override func reuseWithNewParameters(from prototype: Any) {
            super.reuseWithNewParameters(from:prototype)
            guard let arrow = prototype as? Arrow else { return }
            self.number = arrow.number
            self.size = arrow.size
            self.offset = arrow.offset
        }
        func live(update: Update) {
            onRequiredUpdateMake {
                Kite()
                    .in($0, options:.reusable, repeat:number)
                    .batch
                    .reference { $0.previous(Parent.self) }
                    .size(size, on:update.orientation.axis, matchCrossAxis:true)
                    .switch(number, [
                        1 : {
                            $0.baseEdge(update.isPortrait ? .leading : .bottom)
                        },
                        2 : { $0
                            .first {
                                $0.baseEdge(update.isPortrait ? .trailing : .bottom)
                            }
                            .second {
                                $0.baseEdge(update.isPortrait ? .leading : .top)
                            }
                        },
                        4 : {
                            $0.zip([Layout.Edge.trailing, .bottom, .leading, .top]) {
                                $0.mutate.baseEdge($1)
                            }
                        }
                    ])
                    .shift(1.0)
                    .updateShape()
                    .noReference()
                    .center()
                    .switch(number, [
                        2 : {
                            $0.emanate(update.orientation.axis.crossAxis, offset:self.offset)
                        },
                        4 : {
                            $0.emanateGroup(by:3, on:.width, offset:self.offset)
                        }
                    ])
                    .applyTheme()
            }
        }
        public override init() {
            super.init()
        }
        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        public override init(layer:Any) {
            super.init(layer: layer)
        }
    }
    static var theme:Theme {[
        PanView.self => [
            .color(colors.backgroundLuminance())
        ],
        Example.self => [
            .border(width:2.0, color:colors.decoration),
            .color(colors.background),
            .cornerRadius(15.0...30.0)
        ],
        Parent.self => [
            .border(width:4.0...6.0, color:colors.decoration.complement),
            .color(colors.background.complement)
        ],
        (Parent.self | PannableView.self) > TextLayer.self => [
            .textColor(colors.decoration.complement.tinted.alpha(0.2)),
            .typographicContextual {[
                .systemRoundedFont(size:$0.isPortrait ? 50% : 60%, reference:>BaseView.self, relativeAxis:$0.orientation.axis, weight:.black)
            ]}
        ],
        PannableView.self => [
            .compositeBorder {
                $0.width = 4.0...6.0
                $0.color = colors.decoration
                $0.add {
                    $0.width = 1.0...2.0
                    $0.color = colors.decorationLuminance(value:0.2)
                    $0.edgeOffset = -1.5...(-3.0)
                }
            },
            .shadow(opacity:1.0, radius:3.0...5.0)
        ],
        PannableView.self + .normal => [
            .diagonalGradient(start:colors.background, end:colors.decoration),
        ],
        PannableView.self + .selected => [
            .diagonalGradient(start:colors.background.saturated, end:colors.decoration.brighter),
        ],
        PannableView.self > *"grabber" => [
            .color(colors.decoration.darker.alpha(0.1))
        ],
        Kite.self => [
            .color(colors.background)
        ],
        Line.self => [
            .border(width:2.0, color:colors.decoration, dash:.init(style:.dashed))
        ]
    ];}
}

// LEARNING: Custom item mutations API
// In C3UI, extending Mutator (such as the following
// example) is the correct way to make specific
// mutations to specific items (i.e. vs. adding
// methods to the items themselves). This provides
// the most general support, since most item interaction
// is going to be via a Mutator.
// NOTE: Mutator has "dynamic member lookup" in
// case you want to get or set properties only,
// without needing to wrap them in Mutator.

private extension Mutator where T:PanView.PannableView {
    @discardableResult
    func updateArrowDirection(_ onProgress:Bool = true) -> Mutator {
        with { $0.shapes(Kite.self) }
            .onPortrait {
                $0.baseEdge(onProgress ? .leading : .trailing)
            } else: {
                $0.baseEdge(onProgress ? .bottom : .top)
            }
        return chain()
    }
}
