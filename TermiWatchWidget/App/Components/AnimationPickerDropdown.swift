//
//  AnimationPickerDropdown.swift
//  TermiWatchWidget
//

import SwiftUI

struct AnimationPickerDropdown: View {
    @Binding var selectedAnimation: TermiFaceAnimation
    let onAnimationChange: (TermiFaceAnimation) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                selectedAnimationLabel
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LocalizedStringKey("Animation"))

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(TermiFaceAnimation.allCases) { animation in
                        Button {
                            selectedAnimation = animation
                            onAnimationChange(animation)
                            withAnimation(.easeInOut(duration: 0.16)) {
                                isExpanded = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: animation.systemImage)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(animation == selectedAnimation ? .green : .gray)
                                    .frame(width: 24)

                                Text(LocalizedStringKey(animation.titleKey))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)

                                Spacer()

                                if animation == selectedAnimation {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.green)
                                }
                            }
                            .frame(minHeight: 42)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if animation != TermiFaceAnimation.allCases.last {
                            Divider()
                                .overlay(Color.white.opacity(0.12))
                                .padding(.leading, 46)
                        }
                    }
                }
                .background(Color(r: 20, g: 20, b: 20))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .zIndex(1)
            }
        }
    }

    private var selectedAnimationLabel: some View {
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
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(isExpanded ? 0.32 : 0.14), lineWidth: 1)
        }
    }
}
