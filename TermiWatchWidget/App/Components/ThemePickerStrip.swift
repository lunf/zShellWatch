//
//  ThemePickerStrip.swift
//  TermiWatchWidget
//

import SwiftUI

struct ThemePickerStrip: View {
    @Binding var selectedTheme: TermiFaceTheme
    let onThemeChange: (TermiFaceTheme) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TermiFaceTheme.allCases) { theme in
                    Button {
                        selectedTheme = theme
                        onThemeChange(theme)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: theme.systemImage)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(theme.accentColor)
                                .frame(width: 36, height: 36)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            Text(LocalizedStringKey(theme.titleKey))
                                .font(.caption)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 96, height: 78)
                        .background(selectedTheme == theme ? theme.accentColor.opacity(0.22) : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selectedTheme == theme ? theme.accentColor : Color.white.opacity(0.14), lineWidth: selectedTheme == theme ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel(LocalizedStringKey("Theme"))
    }
}
