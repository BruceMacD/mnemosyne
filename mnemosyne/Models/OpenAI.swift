//
//  OpenAI.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-04-29.
//

import Foundation
import OpenAI

public class OpenAIClient {
    var apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func send(message: String) async throws -> ChatResult {
        print(message)
        let configuration = OpenAI.Configuration(token: self.apiKey, timeoutInterval: 60.0)
        let openAI = OpenAI(configuration: configuration)
        let query = ChatQuery(model: .gpt3_5Turbo, messages: [.init(role: .user, content: message)])
        let result = try await openAI.chats(query: query)
        return result
    }
}
