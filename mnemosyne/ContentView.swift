//
//  ContentView.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-04-27.
//

import SwiftUI

struct ContentView: View {
    @State var selection: Set<Int> = [0]
    
    var body: some View {
        ActivityView()
    }
}

struct ActivityView: View {
    @State private var userInput: String = ""
    private let lastChatBubbleID = UUID()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack {
                            Spacer(minLength: geometry.size.height * 1/3)
                            ChatBubble(title: "You", value: "blah blah", icon:"face.smiling")
                            ChatBubble(title: "ChatGPT", value: "blah blah", icon:"face.smiling.fill")
                            ChatBubble(title: "You", value: "blah blah", icon:"face.smiling")
                            ChatBubble(title: "ChatGPT", value: "blah blah", icon:"face.smiling.fill")
                            ChatBubble(title: "You", value: "blah blah", icon:"face.smiling")
                                .id(lastChatBubbleID)
                        }
                        .padding()
                        .onAppear {
                            scrollProxy.scrollTo(lastChatBubbleID, anchor: .bottom)
                        }
                    }
                }
                .frame(height: geometry.size.height * 4/5)
                
                MultilineTextField(text: $userInput, buttonAction: {
                    print("Arrow button clicked")
                })
                    .frame(height: geometry.size.height * 1/5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct MultilineTextField: View {
    @Binding var text: String
    var buttonAction: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .padding([.top, .leading, .bottom])
                .padding(.trailing, 44)
            
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Button(action: buttonAction) {
                        Image(systemName: "arrow.up.circle.fill")
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

struct ChatBubble: View {
    var title: String
    var value: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 6) {
                Group {
                    Image(systemName: icon)
                    Text(title)
                        .font(.headline)
                }
                .foregroundColor(Color(NSColor.systemPink))
                
                Spacer()
                
                Group {
                    Text("5:15 PM")
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.body, design: .rounded))
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
