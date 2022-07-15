//
//  PlaygroundView.swift
//  Gestures
//
//  Created by David James on 2022-05-09.
//

import C3
import Unilib

/// "Playground" for testing various gesture recognizers.
///
/// This can also be used for determining frame values
/// when writing unit tests for C3. E.g. it was used
/// for writing the LinkingTests.
class PlaygroundView : View, Live {
    func live(update: Update) {
        
        mutate.debugRuler(.grid, flip:.auto)
        
        View()
            .in(self, options:.reusable, repeat:6)
            .at([0,3]) { $0
                .color(Color.amber.a400)
            }
            .at([1,4]) { $0
                .color(Color.lightGreen.a200)
            }
            .at([2,5]) { $0
                .color(Color.lightBlue.a200)
            }
            .at([0]) { $0
                .size(width:100.0, height:200.0)
            }
            .at([1]) { $0
                .size(width:300.0, height:400.0)
            }
            .at([2]) { $0
                .size(width:200.0, height:300.0)
            }
            .at([3,4,5]) { $0
                .span(100.0)
            }
            .alpha(0.7)
            .border()
            .reference { $0.parent }
            .at([0,1,2]) { $0
                .align(.edge(.top), offset:update.isPortrait ? 100.0 : 300.0)
                .align(.edge(.leading), offset:update.isPortrait ? 300.0 : 100.0)
            }
            .at([3,4,5]) { $0
                .align(.edge(.top), offset:update.isPortrait ? 100.0 : 100.0)
                .align(.edge(.leading), offset:update.isPortrait ? 100.0 : 100.0)
            }
            .noReference()
            .by(3) { $0
                .link(update.orientation.axis)
            }
            .onPan { pan, view in
                switch pan.state {
                case .ended :
                    view.position = view.position.rounded(multiple:50)
                default : break
                }
            }
            .subscribe()
            .onRotate { rotation, view in
                switch rotation.state {
                case .changed :
                    view.rotate(degrees:rotation.rotation.degrees, replacing:true)
                case .ended :
                    view.rotate(degrees:rotation.rotation.degrees.rounded(multiple:90), replacing:true)
                default :
                    break
                }
            }
            .subscribe()
            .make {
                Layer()
                    .in($0, options:.reusable)
                    .stretchToFit()
                    .height(8.0...15.0)
                    .color(Color.black)
                    .noReference()
                    .top()
                    .centerHorizontally()
                VerticalLine()
                    .in($0, options:.reusable)
                    .strokeColor(Color.black)
                    .center()
                HorizontalLine()
                    .in($0, options:.reusable)
                    .strokeColor(Color.black)
                    .center()
                Circle()
                    .in($0, options:.reusable)
                    .span(20.0...35.0)
                    .color(Color.black)
                    .center()
                    .make(.lifted) {
                        TextLayer()
                            .in($0, options:.reusable)
                            .reference { $0.parent }
                            .systemFont(size:45%, weight:.bold)
                            .textColor(Color.white)
                            .fittedTextFromOrdinal() {
                                "\($0 >= 3 ? $0 - 3 : $0)"
                            }
                            .center()
                    }
            }

        TextLayer()
            .in(self, options:.reusable, repeat:22)
            .textColor(Color.black)
            .at(0...10) { $0
                .fittedTextFromOrdinal() { "\($0 * 10)" }
                .onPortrait { $0
                    .position(x:250.0, y:100.0)
                    .last { $0
                        .position(y:1100.0)
                    }
                    .distributeVertically()
                } else: { $0
                    .position(x:100.0, y:250.0)
                    .last { $0
                        .position(x:1100.0)
                    }
                    .distributeHorizontally()
                }
            }
            .at(11...21) { $0
                .fittedTextFromOrdinal() { "\(($0 - 11) * 10)" }
                .onPortrait { $0
                    .position(x:650.0, y:100.0)
                    .reverse
                    .last { $0
                        .position(y:1100.0)
                    }
                    .distributeVertically()
                } else: { $0
                    .position(x:100.0, y:650.0)
                    .reverse
                    .last { $0
                        .position(x:1100.0)
                    }
                    .distributeHorizontally()
                }
            }

    }
}

// TODO: Finish rotation pan gestures
// This should include "degrees" property.
// Should also ensure you can rotate from an existing
// rotation rather than starting from 0.0 each time.
// Possibly some "perpendicular degrees" support if that makes sense
// but don't limit to only perpendicular. It should remember the
// last rotation.
