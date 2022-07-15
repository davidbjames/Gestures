//
//  AppView.swift
//  Gestures
//
//  Created by David James on 2022-05-08.
//

import C3
import Combine

/// Main "tab" view for navigating between gesture views.
class AppView : View, Live {
    /// Tab pages
    enum Page : String, CaseIterable {
        case playground = "Gesture Playground"
        case panning = "Pan Gestures"
    }
    /// Publisher for switching pages via button taps.
    @Current var currentPage = Page.playground
    
    func live(update: Update) {
        
        View(area:update.isPortrait ? .trailing(90%) : .top(90%))
            .in(self, options:.reusable)
            .masksToBounds(true)
            .onReceiveMake(
                $currentPage.removeDuplicates(),
                subscription: .restartable,
                buildOptions: .variable // to support replacing one page with another
            ) { page, body in
                switch page {
                case .playground :
                    PlaygroundView()
                        .in(body)
                case .panning :
                    PanView()
                        .in(body)
                }
            }
            // "tab bar" occupies the remainder of the view
            .remainder(options:.reusable) {
                TabBar($currentPage)
                    .in($0)
            }
    }
    class TabBar : View, Live, Themeable {
        var currentPage:CurrentValue<Page>!
        init(_ publisher:CurrentValue<Page>) {
            self.currentPage = publisher
            super.init(frame:.zero)
        }
        func live(update: Update) {
            TabButton()
                .in(self, data:Page.allCases)
                .onPortrait { $0
                    .turn(.quarter)
                    .mutate(includeTransforms:true)
                    .stretchHorizontally()
                    .spreadVertically()
                } else: { $0
                    .resetTransform()
                    .stretchVertically()
                    .spreadHorizontally()
                }
                .onTap {
                    self.currentPage.send($0.page)
                }
        }
        class TabButton : ExclusiveButton, LiveWithData, ControlStateUpdatable {
            typealias Model = Page
            var page:Page!
            func live(data page:Model, update: Update) {
                self.page = page
                mutate
                    .text(page.rawValue)
                    .onCreate { $0
                        .textAlignment(.center)
                        .numberOfLines(2)
                        .select(ordinal:0) { $0
                            .selected(true)
                        }
                        .applyTheme()
                    }
            }
        }
        static var theme:Theme {[
            TabButton.self => [
                .font(fonts.text.boldStyle),
                .fontSize(24.0...36.0)
            ],
            TabButton.self + .normal => [
                .color(colors.background),
                .textColor(colors.text)
            ],
            TabButton.self + .selected => [
                .color(colors.backgroundLuminance(inverse:true)),
                .textColor(colors.textLuminance(value:-0.1, inverse:true))
            ]
        ];}
        
        public override init(frame:CGRect) {
            super.init(frame: frame)
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// TODO: Review AppView navigation for reusability simplifiction.
// As part of this, review both "variable" attachment (which handles
// removing the old view w/animation) and "Presentable" (to see if
// it makes sense to introduce that, also wrt variable attachement
// since it already handles animation and detachment)
