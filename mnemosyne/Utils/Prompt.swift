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
        Given the queries I have asked previously (in the previous section), and your replies (in the replied section), answer my new query.
        Previous section:
        \(questionsText)
        
        Replied section:
        \(repliedText)
        
        New query:
        \(sanitizedQuery)
        """
        
        return prompt
    }
}
