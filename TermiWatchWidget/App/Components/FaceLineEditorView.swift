//
//  FaceLineEditorView.swift
//  TermiWatchWidget
//

import SwiftUI

struct FaceLineEditorView: View {
    @Binding var terminalUser: String
    @Binding var machineName: String
    @Binding var selectedLines: [TermiFaceLine]
    let onPromptIdentityChange: () -> Void
    let onLinesChange: ([TermiFaceLine]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    private var availableLines: [TermiFaceLine] {
        qAvailableFaceLines.filter { !selectedLines.contains($0) }
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    var body: some View {
        NavigationStack {
            List {
                Section(LocalizedStringKey("Terminal User")) {
                    TextField(LocalizedStringKey("Terminal User"), text: $terminalUser)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(onPromptIdentityChange)
                }

                Section(LocalizedStringKey("Machine Name")) {
                    TextField(LocalizedStringKey("Machine Name"), text: $machineName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(onPromptIdentityChange)
                }

                Section(LocalizedStringKey("Displayed Lines")) {
                    ForEach(selectedLines) { line in
                        Text(LocalizedStringKey(line.titleKey))
                    }
                    .onMove(perform: moveLines)
                    .onDelete(perform: removeLines)
                }

                Section(LocalizedStringKey("Available Lines")) {
                    ForEach(availableLines) { line in
                        Button {
                            addLine(line)
                        } label: {
                            HStack {
                                Text(LocalizedStringKey(line.titleKey))
                                Spacer()
                                Image(systemName: "plus.circle")
                            }
                        }
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.45 : 1)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Face Lines"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isEditing {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel(LocalizedStringKey("Done"))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            editMode = isEditing ? .inactive : .active
                        }
                    } label: {
                        Image(systemName: isEditing ? "checkmark.circle" : "arrow.up.arrow.down")
                    }
                    .accessibilityLabel(isEditing ? LocalizedStringKey("Done") : LocalizedStringKey("Edit"))
                }
            }
            .environment(\.editMode, $editMode)
        }
    }

    private func addLine(_ line: TermiFaceLine) {
        selectedLines.append(line)
        onLinesChange(selectedLines)
    }

    private func moveLines(from source: IndexSet, to destination: Int) {
        selectedLines.move(fromOffsets: source, toOffset: destination)
        onLinesChange(selectedLines)
    }

    private func removeLines(at offsets: IndexSet) {
        selectedLines.remove(atOffsets: offsets)
        onLinesChange(selectedLines)
    }
}
