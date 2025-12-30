//
//  GitModels.swift
//  tibok
//
//  Git-related data models
//

import Foundation

/// Represents a git commit
struct GitCommit: Identifiable, Hashable {
    let id: String // Same as hash
    let hash: String
    let shortHash: String
    let author: String
    let email: String
    let date: Date
    let message: String

    init(hash: String, shortHash: String, author: String, email: String, date: Date, message: String) {
        self.id = hash
        self.hash = hash
        self.shortHash = shortHash
        self.author = author
        self.email = email
        self.date = date
        self.message = message
    }
}
