//
//  DocumentInspectorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2025 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import Observation
import Combine
import FileEncoding
import FilePermissions
import LineEnding
import Syntax

final class DocumentInspectorViewController: NSHostingController<DocumentInspectorView> {
    
    // MARK: Public Properties
    
    let model = DocumentInspectorViewModel()
    
    
    // MARK: Lifecycle
    
    required init(document: DataDocument?) {
        
        self.model.document = document
        
        super.init(rootView: DocumentInspectorView(model: self.model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.model.isPresented = true
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.isPresented = false
    }
}


@MainActor @Observable final class DocumentInspectorViewModel: DocumentInspectorView.ModelProtocol {
    
    var attributes: FileAttributes?  { self.document?.fileAttributes }
    var fileURL: URL?
    var textSettings: TextSettings?
    var countResult: EditorCounter.Result?  { (self.document as? Document)?.counter.result }
    
    fileprivate var isPresented = false  { didSet { self.invalidateObservation() } }
    var document: DataDocument?  { willSet { self.cancelObservation() } didSet { self.didUpdateDocument() } }
    
    private var observers: Set<AnyCancellable> = []
    
    
    // MARK: Private Methods
    
    /// Updates observations.
    private func didUpdateDocument() {
        
        self.textSettings = if let document = self.document as? Document {
            TextSettings(encoding: document.fileEncoding, lineEnding: document.lineEnding, mode: document.mode)
        } else {
            nil
        }
        
        if self.isPresented {
            self.startObservation()
        }
    }
    
    
    /// Invalidates observation on the document depending on the current view visibility state.
    private func invalidateObservation() {
        
        if self.isPresented {
            self.startObservation()
        } else {
            self.cancelObservation()
        }
    }
    
    
    /// Starts observations on the document.
    private func startObservation() {
        
        if let document = document as? Document {
            document.counter.updatesAll = true
            
            self.observers = [
                document.publisher(for: \.fileURL, options: .initial)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.fileURL = $0 },
                document.$fileEncoding
                    .sink { [weak self] in self?.textSettings?.encoding = $0 },
                document.$lineEnding
                    .sink { [weak self] in self?.textSettings?.lineEnding = $0 },
                document.$mode
                    .sink { [weak self] in self?.textSettings?.mode = $0 },
            ]
            
        } else if let document {
            self.observers = [
                document.publisher(for: \.fileURL, options: .initial)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.fileURL = $0 },
            ]
        }
    }
    
    
    /// Cancels the observations on the document.
    private func cancelObservation() {
        
        (self.document as? Document)?.counter.updatesAll = false
        self.observers.removeAll()
    }
}


// MARK: - View

struct TextSettings {
    
    var encoding: FileEncoding
    var lineEnding: LineEnding
    var mode: Mode
}


struct DocumentInspectorView: View {
    
    @MainActor protocol ModelProtocol {
        
        var attributes: FileAttributes? { get }
        var fileURL: URL? { get }
        var textSettings: TextSettings? { get }
        var countResult: EditorCounter.Result? { get }
    }
    
    
    @State var model: any ModelProtocol
    
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                DocumentFileView(attributes: self.model.attributes, fileURL: self.model.fileURL)
                
                if let textSettings = self.model.textSettings {
                    Divider()
                    TextSettingsView(value: textSettings)
                }
                
                if let countResult = self.model.countResult {
                    Divider()
                    EditorCountView(result: countResult)
                    
                    Divider()
                    CharacterPaneView(character: countResult.character)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 12, trailing: 12))
            .disclosureGroupStyle(InspectorDisclosureGroupStyle())
            .labeledContentStyle(InspectorLabeledContentStyle())
        }
        .accessibilityLabel(String(localized: "InspectorPane.document.label",
                                   defaultValue: "Document Inspector", table: "Document"))
        .controlSize(.small)
    }
}


private struct DocumentFileView: View {
    
    var attributes: FileAttributes?
    var fileURL: URL?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "File", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(String(localized: "Created", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.attributes?.creationDate?.formatted(date: .abbreviated, time: .shortened))
                LabeledContent(String(localized: "Modified", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.attributes?.modificationDate?.formatted(date: .abbreviated, time: .shortened))
                LabeledContent(String(localized: "Size", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.attributes?.size.formatted(.byteCount(style: .file, includesActualByteCount: true)))
                
                LabeledContent(String(localized: "Tags", table: "Document", comment: "label in document inspector")) {
                    if let tags = self.attributes?.tags, !tags.isEmpty {
                        WrappingHStack(horizontalSpacing: 7) {
                            ForEach(Array(tags.enumerated()), id: \.offset) { (_, tag) in
                                HStack(spacing: 4) {
                                    TagColorView(color: tag.color)
                                        .frame(height: 9)
                                    Text(tag.name)
                                }.accessibilityLabel(tag.name)
                            }
                        }
                    } else {
                        Text.none
                    }
                }
                LabeledContent(String(localized: "Permissions", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.attributes?.permissions.formatted())
                LabeledContent(String(localized: "Owner", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.attributes?.owner)
                
                LabeledContent(String(localized: "Full Path", table: "Document", comment: "label in document inspector")) {
                    if let fileURL = self.fileURL {
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text(fileURL, format: .url.scheme(.never))
                                .lineLimit(5)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                                .foregroundStyle(.primary)
                                .help(fileURL.formatted(.url.scheme(.never)))
                            Button(String(localized: "Show in Finder", table: "Document"), systemImage: "arrow.forward") {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            }
                            .symbolVariant(.circle.fill)
                            .fontWeight(.bold)
                            .labelStyle(.iconOnly)
                            .controlSize(.mini)
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Text.none
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct TextSettingsView: View {
    
    var value: TextSettings
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Text Settings", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(String(localized: "Encoding", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.value.encoding.localizedName)
                LabeledContent(String(localized: "Line Endings", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.value.lineEnding.label)
                LabeledContent(String(localized: "Mode", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.value.mode.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct EditorCountView: View {
    
    var result: EditorCounter.Result
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Count", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(String(localized: "Lines", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.result.lines.formatted)
                .accessibilityAddTraits(.updatesFrequently)
                LabeledContent(String(localized: "Characters", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.result.characters.formatted)
                .accessibilityAddTraits(.updatesFrequently)
                LabeledContent(String(localized: "Words", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.result.words.formatted)
                .accessibilityAddTraits(.updatesFrequently)
                .padding(.bottom, 8)
                
                LabeledContent(String(localized: "Location", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.result.location?.formatted())
                .accessibilityAddTraits(.updatesFrequently)
                LabeledContent(String(localized: "Line", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.result.line?.formatted())
                .accessibilityAddTraits(.updatesFrequently)
                LabeledContent(String(localized: "Column", table: "Document",
                                      comment: "label in document inspector"),
                               optional: self.result.column?.formatted())
                .accessibilityAddTraits(.updatesFrequently)
            }
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct CharacterPaneView: View {
    
    var character: Character?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Character", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                if let scalars = self.character?.unicodeScalars {
                    let label = (scalars.count == 1)
                    ? String(localized: "Code Point", table: "Document",
                             comment: "label in document inspector")
                    : String(localized: "Code Points", table: "Document",
                             comment: "label in document inspector")
                    LabeledContent(label) {
                        WrappingHStack {
                            ForEach(Array(scalars.enumerated()), id: \.offset) { (_, scalar) in
                                Text(scalar.codePoint)
                                    .monospacedDigit()
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 2)
                                    .overlay(RoundedRectangle(cornerRadius: 3.5)
                                        .strokeBorder(.tertiary))
                            }
                        }
                    }
                    if scalars.count == 1, let scalar = scalars.first {
                        LabeledContent(String(localized: "Name", table: "Document",
                                              comment: "label in document inspector"),
                                       optional: scalar.name)
                        LabeledContent(String(localized: "Block", table: "Document",
                                              comment: "label in document inspector"),
                                       optional: scalar.localizedBlockName)
                        let category = scalar.properties.generalCategory
                        LabeledContent(String(localized: "Category", table: "Document",
                                              comment: "label in document inspector"),
                                       value: "\(category.longName) (\(category.shortName))")
                    }
                } else {
                    Text("Not selected", tableName: "Document", comment: "placeholder")
                        .foregroundStyle(.tertiary)
                        .help(String(localized: "Select a single character to show Unicode information.", table: "Document", comment: "tooltip"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct InspectorDisclosureGroupStyle: DisclosureGroupStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        DisclosureGroup(isExpanded: configuration.$isExpanded) {
            configuration.content
        } label: {
            configuration.label
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}


private struct InspectorLabeledContentStyle: LabeledContentStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        LabeledContent {
            configuration.content
        } label: {
            configuration.label
                // keep specific width for short labels, such as Chinese
                .frame(minWidth: 48, alignment: .trailing)
        }.padding(.bottom, 1)
    }
}


// MARK: - Preview

@MainActor private struct MockedModel: DocumentInspectorView.ModelProtocol {
    
    var attributes: FileAttributes?
    var fileURL: URL?
    var textSettings: TextSettings?
    var countResult: EditorCounter.Result?
    
    var document: DataDocument?
}


#Preview(traits: .fixedLayout(width: 240, height: 520)) {
    @Previewable @State var model = MockedModel(
        attributes: .init(
            creationDate: .now,
            modificationDate: .now,
            size: 1024,
            permissions: FilePermissions(mask: 0o644),
            owner: "clarus",
            tags: [FinderTag(name: "Green", color: .green),
                   FinderTag(name: "Blue", color: .blue),
                   FinderTag(name: "None")]
        ),
        fileURL: URL(filePath: "/Users/clarus/Desktop/My Script.py"),
        textSettings: .init(
            encoding: .init(encoding: .utf8, withUTF8BOM: true),
            lineEnding: .lf,
            mode: .kind(.general)
        ),
        countResult: .init())
    
    model.countResult?.characters = .init(entire: 1024, selected: 4)
    model.countResult?.lines = .init(entire: 10, selected: 1)
    model.countResult?.character = "🐈‍⬛"
    
    return DocumentInspectorView(model: model)
}


#Preview("Empty", traits: .fixedLayout(width: 240, height: 520)) {
    DocumentInspectorView(model: MockedModel())
}
