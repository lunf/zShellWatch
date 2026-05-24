//
//  TerminalTextViews.swift
//  TermiWatchWidget
//

import SwiftUI

struct SmallCircularView : View {
    var image: String?
    var text : String?

    var body: some View {
        if let image = image{
            Image(contentsOf: image)?.resizable()
        }else{
            Text(text ?? "Q")
        }
    }
}



struct MyText: View {
    let text: String
    let fontSize: CGFloat?
    let color: Color?
    @Environment(\.termiFaceTheme) private var theme

    init(_ text: String) {
        self.text = text
        self.fontSize = nil
        self.color = nil
    }
    
    init(_ text: String, fontSize: CGFloat, color: Color? = nil){
        self.text = text
        self.fontSize = fontSize
        self.color = color
    }

    init(_ text: String, color: Color){
        self.text = text
        self.fontSize = nil
        self.color = color
    }
    
    private var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [
                .red,
                .orange,
                .yellow,
                .green,
                .cyan,
                .blue,
                .purple
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    var body: some View{
        if theme == .cloud {
            Text(text)
                .font(Font.custom(theme.fontName, size: fontSize ?? theme.fontSize))
                .foregroundStyle(rainbowGradient)
                .frame(alignment: .leading)
        } else {
            Text(text)
                .font(Font.custom(theme.fontName, size: fontSize ?? theme.fontSize))
                .foregroundStyle(color ?? theme.textColor)
                .frame(alignment: .leading)
        }
    }

}
