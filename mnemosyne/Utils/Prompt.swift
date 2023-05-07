//
//  Prompt.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-05-07.
//

import Foundation

class Prompt {
    static func createPrompt(questions: [String], replies: [String], sanitizedQuery: String) -> String {
        let questionsText = questions.joined(separator: "\n")
        let repliedText = replies.joined(separator: "\n")
        
        // TODO: limit lengths
        
        let prompt = """
        Given the questions I have asked previously (in the questions section), and your previous replies (in the replied section), answer my new question.
        Questions section:
        \(questionsText)
        Replied section:
        \(repliedText)
        Question:
        \(sanitizedQuery)
        """
        
        return prompt
    }
}
