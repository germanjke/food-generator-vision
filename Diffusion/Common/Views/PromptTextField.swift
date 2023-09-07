//
//  PromptTextField.swift
//  Diffusion-macOS
//
//  Created by Dolmere on 22/06/2023.
//  See LICENSE at https://github.com/huggingface/swift-coreml-diffusers/LICENSE
//

import SwiftUI
import Combine
import StableDiffusion

struct PromptTextField: View {
    @State private var output: String = ""
    @State private var input: String = ""
    @State private var typing = false
    @State private var tokenCount: Int = 0
    @State var isPositivePrompt: Bool = true
    @State private var tokenizer: BPETokenizer?
    @State private var currentModelVersion: String = ""
    @State private var prompts: [String] = ["Positive prompt"]
    @State private var promptOptions = ["Bacon", "Tomatoes", "Eggs", "Salami",
                                        "Waterlemon", "Olives", "Pancakes"]
    @State private var textValues: [String] = [""]
    @State private var randomPrompts: [String] = ["Enter some food from your fridge"]
    @State private var userInputs: [String] = [""] // Массив для хранения введенных пользователем значений


    @Binding var textBinding: String
    @Binding var model: String // the model version as it's stored in Settings

    private let maxTokenCount = 77

    private var modelInfo: ModelInfo? {
        ModelInfo.from(modelVersion: $model.wrappedValue)
    }
    
    private var filename: String? {
        let variant = modelInfo?.bestAttention ?? .original
        return modelInfo?.modelURL(for: variant).lastPathComponent
    }
    
    private var downloadedURL: URL? {
        if let filename = filename {
            return PipelineLoader.models.appendingPathComponent(filename)
        }
        return nil
    }
    
    private var packagesFilename: String? {
        (filename as NSString?)?.deletingPathExtension
    }
    
    private var compiledURL: URL? {
        if let packagesFilename = packagesFilename {
            return downloadedURL?.deletingLastPathComponent().appendingPathComponent(packagesFilename)
        }
        return nil
    }
    
    private var textColor: Color {
        switch tokenCount {
        case 0...65:
            return .green
        case 66...75:
            return .orange
        default:
            return .red
        }
    }
    
    // macOS initializer
    init(text: Binding<String>, isPositivePrompt: Bool, model: Binding<String>) {
         _textBinding = text
         self.isPositivePrompt = isPositivePrompt
        _model = model
    }
    
    // iOS initializer
    init(text: Binding<String>, isPositivePrompt: Bool, model: String) {
        _textBinding = text
        self.isPositivePrompt = isPositivePrompt
        _model = .constant(model)
    }
    
    var randomPrompt: String {
        return promptOptions.randomElement() ?? ""
    }
    
    func updateUserInput(index: Int) {
            if index >= 0 && index < userInputs.count {
                userInputs[index] = textValues[index]
            }
        }

    var body: some View {
        HStack {
            VStack {
                #if os(macOS)
                ForEach(0..<prompts.count, id: \.self) { index in
                    let prompt = isPositivePrompt ? randomPrompts[index] : "You don't like to eat"
                    let user_text = Binding(
                        get: { textValues[index] },
                        set: { newValue in
                            textValues[index] = newValue
                            updateUserInput(index: index)
                            //textBinding = Binding.constant(newValue)
                            //textBinding = newValue
                            textBinding = userInputs.joined(separator: " ")
                        }
                    )
                    
                    TextField(prompt, text: user_text, axis: .vertical)
                    //                TextField(isPositivePrompt ? randomPrompts[index] : "You don't like to eat",
                    //                          text: $textValues[index], onEditingChanged: { _ in
                    //                    updateUserInput(index: index)
                    //                  }, axis: .vertical)
                    //                TextField(isPositivePrompt ? randomPrompt : "Negative Prompt",
                    //                          text: $textValues[index], axis: .vertical)
                        .lineLimit(20)
                        .textFieldStyle(.squareBorder)
                        .listRowInsets(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: 20))
                        .foregroundColor(textColor == .green ? .primary : textColor)
                        .frame(minHeight: 30)
                }
                
                //            Button(action: {
                //                prompts.append("New Prompt") // just for updat ForEach
                //                textValues.append("")
                //                randomPrompts.append(self.randomPrompt)
                //                userInputs.append("")
                //            }) {
                //                Image(systemName: "plus.message.fill")
                //                    .foregroundColor(.blue)
                //                    .imageScale(.large)
                //            }
                //            Button(action: {
                //                        // Удаляем последний элемент из массивов
                //                if prompts.count > 0 {
                //                    prompts.removeLast()
                //                    textValues.removeLast()
                //                    randomPrompts.removeLast()
                //                    userInputs.removeLast()
                //                }
                //            }) {
                //                Image(systemName: "minus.circle.fill")
                //                    .foregroundColor(.red)
                //                    .imageScale(.large)
                //            }
                if modelInfo != nil && tokenizer != nil {
                    HStack {
                        Spacer()
                        if !textBinding.isEmpty {
                            Text("\(tokenCount)")
                                .foregroundColor(textColor)
                            Text(" / \(maxTokenCount)")
                        }
                    }
                    .onReceive(Just(textBinding)) { text in
                        updateTokenCount(newText: text)
                    }
                    .font(.caption)
                }
                #else
                TextField("Prompt", text: $textBinding, axis: .vertical)
                    .lineLimit(20)
                    .listRowInsets(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: 20))
                    .foregroundColor(textColor == .green ? .primary : textColor)
                    .frame(minHeight: 30)
                HStack {
                    if !textBinding.isEmpty {
                        Text("\(tokenCount)")
                            .foregroundColor(textColor)
                        Text(" / \(maxTokenCount)")
                    }
                    Spacer()
                }
                .onReceive(Just(textBinding)) { text in
                    updateTokenCount(newText: text)
                }
                .font(.caption)
                #endif
            }
            
            Spacer()
            
            HStack { // Обернуть кнопки в горизонтальный стек
                Button(action: {
                    prompts.append("New Prompt") // just for updat ForEach
                    textValues.append("")
                    randomPrompts.append(self.randomPrompt)
                    userInputs.append("")
                }) {
                    Image(systemName: "plus.message.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                Button(action: {
                    // Удаляем последний элемент из массивов
                    if prompts.count > 0 {
                        prompts.removeLast()
                        textValues.removeLast()
                        randomPrompts.removeLast()
                        userInputs.removeLast()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
            }
            //.padding(.top, 20)
        }
        .onChange(of: model) { model in
            updateTokenCount(newText: textBinding)
        }
        .onAppear {
            updateTokenCount(newText: textBinding)
        }
    }

    private func updateTokenCount(newText: String) {
        // ensure that the compiled URL exists
        guard let compiledURL = compiledURL else { return }
        // Initialize the tokenizer only when it's not created yet or the model changes
        // Check if the model version has changed
        let modelVersion = $model.wrappedValue
        if modelVersion != currentModelVersion {
            do {
                tokenizer = try BPETokenizer(
                    mergesAt: compiledURL.appendingPathComponent("merges.txt"),
                    vocabularyAt: compiledURL.appendingPathComponent("vocab.json")
                )
                currentModelVersion = modelVersion
            } catch {
                print("Failed to create tokenizer: \(error)")
                return
            }
        }
        let (tokens, _) = tokenizer?.tokenize(input: newText) ?? ([], [])

        DispatchQueue.main.async {
            self.tokenCount = tokens.count
        }
    }
}
