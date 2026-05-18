//
//  AnimationPickerDropdown.swift
//  TermiWatchWidget
//

import SwiftUI

struct AnimationPickerDropdown: View {
    @Binding var selectedAnimation: TermiFaceAnimation
    let onAnimationChange: (TermiFaceAnimation) -> Void

    var body: some View {
        Menu {
            ForEach(TermiFaceAnimation.allCases) { animation in
                Button {
                    selectedAnimation = animation
                    onAnimationChange(animation)
                } label: {
                    Label(LocalizedStringKey(animation.titleKey), systemImage: animation.systemImage)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: selectedAnimation.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("Animation"))
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(LocalizedStringKey(selectedAnimation.titleKey))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("Animation"))
    }
}
