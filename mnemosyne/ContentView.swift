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
    private let openAIClient = OpenAIClient(apiKey: "sk-api-token")
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                VStack {
                    ScrollView {
                        GeometryReader { innerGeometry in
                            VStack {
                                if messages.isEmpty {
                                    Spacer(minLength: innerGeometry.size.height / 2 - 50)
                                }
                                
                                ForEach(messages) { message in
                                    ChatBubbleView(chatMessage: message)
                                }
                                
                                if messages.isEmpty {
                                    Spacer(minLength: geometry.size.height / 4)
                                    HStack {
                                        Spacer()
                                        Image(systemName: "message")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
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
                    
                    MultilineTextField(text: $userInput, buttonAction: {
                        Task {
                            do {
                                let msg = userInput
                                messages.append(ChatMessage(sender: "You", content: msg, icon: "face.smiling", timestamp: currentTimeAsString()))
                                userInput = ""
                                let response = try await openAIClient.send(message: msg)
                                messages.append(ChatMessage(sender: "ChatGPT", content: response.choices[0].message.content, icon: "face.smiling.fill", timestamp: currentTimeAsString()))
                            } catch {
                                print("Error sending message: \(error)")
                            }
                        }
                    })
                    .frame(height: geometry.size.height * 1/5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        isLoading = true
                        Task {
                            await buttonAction()
                            isLoading = false
                        }
                    }) {
                        Image(systemName: isLoading ? "" : "arrow.up.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(NSColor.systemPink))
                            .frame(width: 24, height: 24)
                            .background(Color.clear)
                            .overlay(
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(NSColor.systemPink)))
                                            .frame(width: 24, height: 24)
                                    } else {
                                        EmptyView()
                                    }
                                }
                            )
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
