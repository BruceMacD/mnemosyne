//
//  Prompt.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-05-07.
//

import Foundation

class Prompt {
    // ChatGPT 3 has a 4096-token limit, GPT4 (8K) has an 8000-token limit and GPT4 (32K) has a 32000-token limit
    // A helpful rule of thumb is that one token generally corresponds to ~4 characters of text for common English text.
    // So ChatGPT 3 token limit is ~16384 characters, set our limit lower (16K) to be safe.
    static let characterLimit = 16000
    
    static func createPrompt(questions: [String], replies: [String], query: String) -> String {
        // make sure we don't go over the max prompt length
        let basePrompt = """
        Given the queries I have asked previously (in the previous section), and your replies (in the replied section), answer my new query.
        Previous section:
        
        Replied section:
        
        New query:
        \(query)
        """
        
        var promptLength = basePrompt.count + query.count
        var questionsText = ""
        var repliedText = ""
        
        var index = 0
        while (promptLength < characterLimit) {
            if (index >= questions.count && index >= replies.count) {
                break
            }
            if (index < questions.count && (promptLength + questions[index].count) < characterLimit) {
                questionsText += questions[index]
                questionsText += "\n"
                promptLength += questions[index].count
            }
            if (index < replies.count && (promptLength + replies[index].count + "\n".count) < characterLimit) {
                repliedText += replies[index]
                repliedText += "\n"
                promptLength += replies[index].count
            }
            index += 1
        }
        
        let prompt = basePrompt.replacingOccurrences(of: "Previous section:\n", with: "Previous section:\n\(questionsText)")
            .replacingOccurrences(of: "Replied section:\n", with: "Replied section:\n\(repliedText)")
        
        return prompt
    }
}

