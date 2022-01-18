//
//  Theme.swift
//  Gestures
//
//  Created by David James on 2021-12-14.
//

import C3

public class AppColors : SemanticPalette {
    public var dark: ColorDerivable = Color.lightGreen.s900
    public var light: ColorDerivable = Color.lightGreen.s200
    public var primary: ColorDerivable = Color.lightGreen.s600
    public var secondary: ColorDerivable = Color.lightGreen.a400
    public var accent: ColorDerivable = Color.amber.a400
    public var lightOnDarkIsNormal: Bool = false
    public var buttonsAreImplicitlyInverted: Bool = false // default
    public var contrastForDeselection: CGFloat = 0.2 // default
    public var desaturationForDeselection: CGFloat = 0.0 // default
    public var saturationForDecoration: CGFloat = 0.3 // default
    //public var foregroundContrast: CGFloat? = -0.2
    
    public var accessibilityOverrides: AccessibilityOverrides?
}

public class AppFonts : DefaultSemanticFontSet {}

public class AppStyleDefaults : ExtendedStyleDefaults {
    public var offsets:OffsetPair = 5.0...10.0
    public var insets:InsetGroup = 5.0...10.0
}

extension Theme : ExtendedStyleAccessible {
    public static var colors = AppColors()
    public static var fonts = AppFonts()
    public static var defaults = AppStyleDefaults()
}

extension NSObject : ExtendedStyleAccessible {
    public static var colors = Theme.colors
    public static var fonts = Theme.fonts
    public static var defaults = Theme.defaults
}

extension NSObject : ThemeAccessible {
    public var defaultTheme:Theme {[
        
    ];}
}
