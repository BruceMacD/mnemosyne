//
//  ContentView.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-04-27.
//

import SwiftUI
import Foundation

func currentTimeAsString() -> String {
    let currentTime = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    let timeString = formatter.string(from: currentTime)
    return timeString
}

struct ContentView: View {
    @State var selection: Set<Int> = [0]
    
    var body: some View {
        ActivityView()
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let sender: String
    let content: String
    let icon: String
    let timestamp: String
}

struct ActivityView: View {
    @State private var userInput: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var responsePending = false
    @State private var apiKey: String = ""
    
    private let openAIClient: OpenAIClient
    private let milvusQueryClient = MilvusClient(host: "localhost", collectionName: "query_history", port: 19530, dimension: 1536)
    private let milvusReplyClient = MilvusClient(host: "localhost", collectionName: "response_history", port: 19530, dimension: 1536)
    
    init() {
        if let savedApiKey = UserDefaults.standard.string(forKey: "apiKey") {
            openAIClient = OpenAIClient(apiKey: savedApiKey)
        } else {
            openAIClient = OpenAIClient(apiKey: "")
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                VStack {
                    ScrollView {
                        VStack {
                            Spacer(minLength: 0)
                                            
                            ForEach(messages) { message in
                                ChatBubbleView(chatMessage: message)
                            }
                                            
                            if responsePending {
                                HStack {
                                    Spacer()
                                    LoadingDots()
                                    Spacer()
                                }
                            }
                            
                            if messages.isEmpty {
                                Spacer(minLength: geometry.size.height / 6)
                                HStack {
                                    Spacer()
                                    Image("logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 250, height: 250)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                        .id(messages.last?.id)
                        .padding()
                        }
                        .frame(height: geometry.size.height * 4/5)
                        .onChange(of: messages) { _ in
                        withAnimation {
                            if let lastMessageID = messages.last?.id {
                                scrollProxy.scrollTo(lastMessageID, anchor: .bottom)
                            }
                        }
                    }
                    if openAIClient.apiKey == "" {
                        TextField("Enter OpenAI API Key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button(action: {
                            UserDefaults.standard.set(apiKey, forKey: "apiKey")
                            openAIClient.apiKey = apiKey
                        }) {
                            Text("Submit")
                                .padding()
                                .cornerRadius(8)
                        }
                    } else {
                        MultilineTextField(text: $userInput, buttonAction: {
                            Task {
                                do {
                                    responsePending = true
                                    let msg = userInput
                                    messages.append(ChatMessage(sender: "You", content: msg, icon: "face.smiling", timestamp: currentTimeAsString()))
                                    userInput = ""
                                    
                                    let embedding = try await openAIClient.embed(message: msg)
                                    milvusQueryClient.insert(query: msg, embedding: embedding)
                                    // find any similar previous queries and responses
                                    let similarQs = milvusQueryClient.query(embedding: embedding)
                                    let similarReplies = milvusReplyClient.query(embedding: embedding)
                                    
                                    let prompt = Prompt.createPrompt(questions: similarQs, replies: similarReplies, sanitizedQuery: msg)
                        
                                    let response = try await openAIClient.chat(message: prompt)
                                    let respMsg = response.choices[0].message.content
                                    responsePending = false
                                    messages.append(ChatMessage(sender: "ChatGPT", content: respMsg, icon: "face.smiling.fill", timestamp: currentTimeAsString()))
                                    let respEmbedding = try await openAIClient.embed(message: respMsg)
                                    milvusReplyClient.insert(query: respMsg, embedding: respEmbedding)
                                } catch {
                                    print("Error sending message: (error)")
                                }
                                responsePending = false
                            }
                        })
                        .frame(height: geometry.size.height * 1/5)
                    }
                }
            }
        }
    }
}

struct LoadingDots: View {
    @State private var animationIndex = 0

    var body: some View {
        HStack {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(Color.white.opacity(animationIndex == index ? 1.0 : 0.2))
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.2), value: animationIndex)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                animationIndex = (animationIndex + 1) % 3
            }
        }
    }
}


struct MultilineTextField: View {
    @Binding var text: String
    var buttonAction: () async -> Void
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .padding([.top, .leading, .bottom])
                .padding(.trailing, 44)
            
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await buttonAction()
                        }
                    }) {
                        Image(systemName: isLoading ? "" : "arrow.up.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(NSColor.systemPink))
                            .frame(width: 24, height: 24)
                            .background(Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    
                    Spacer()
                }
                .padding(.trailing)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding()
    }
}

struct ChatBubbleView: View {
    var chatMessage: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 6) {
                Group {
                    Image(systemName: chatMessage.icon)
                    Text(chatMessage.sender)
                        .font(.headline)
                }
                .foregroundColor(Color(NSColor.systemPink))
                
                Spacer()
                
                Group {
                    Text(chatMessage.timestamp)
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(chatMessage.content)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(nil) // Allow text to wrap to multiple lines
                    .fixedSize(horizontal: false, vertical: true) // Let the height grow as needed
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
