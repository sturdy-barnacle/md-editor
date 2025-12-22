//
//  LogService.swift
//  tibok
//
//  Centralized logging service for debugging and error reporting
//  Logs are written to ~/Library/Logs/tibok/tibok.log
//

import Foundation
import AppKit

@MainActor
final class LogService {

    // MARK: - Singleton

    static let shared = LogService()

    private init() {
        createLogDirectoryIfNeeded()
    }

    // MARK: - Properties

    private let logDirectory: URL = {
        let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs")
            .appendingPathComponent("tibok")
        return logsDir
    }()

    private var logFileURL: URL {
        logDirectory.appendingPathComponent("tibok.log")
    }

    private let maxLogSize: Int = 5 * 1024 * 1024 // 5MB

    // MARK: - Log Levels

    enum LogLevel: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
    }

    // MARK: - Public Methods

    /// Log a message with specified level
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        let logEntry = "\(timestamp) [\(level.rawValue)] [\(filename):\(line)] \(function) - \(message)\n"

        // Write to file
        writeToFile(logEntry)

        // Also output to console for development
        NSLog("\(level.rawValue) \(message)")
    }

    /// Log debug message
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// Log info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Log warning message
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Log error message
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    /// Log error with full details
    func error(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var message = "Error: \(error.localizedDescription)"

        let nsError = error as NSError
        message += "\n  Domain: \(nsError.domain)"
        message += "\n  Code: \(nsError.code)"
        if !nsError.userInfo.isEmpty {
            message += "\n  UserInfo: \(nsError.userInfo)"
        }

        if let context = context {
            message = "\(context)\n\(message)"
        }

        log(message, level: .error, file: file, function: function, line: line)
    }

    /// Get the log file path
    func getLogFilePath() -> String {
        return logFileURL.path
    }

    /// Read the log file contents
    func readLogFile() -> String? {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return nil
        }
        return try? String(contentsOf: logFileURL, encoding: .utf8)
    }

    /// Clear the log file
    func clearLog() {
        try? FileManager.default.removeItem(at: logFileURL)
        log("Log file cleared", level: .info)
    }

    /// Open log file in Finder
    func revealLogFile() {
        NSWorkspace.shared.activateFileViewerSelecting([logFileURL])
    }

    /// Copy log file path to clipboard
    func copyLogPathToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logFileURL.path, forType: .string)
    }

    // MARK: - Private Methods

    private func createLogDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: logDirectory.path) {
            try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
    }

    private func writeToFile(_ message: String) {
        // Check if log rotation is needed
        rotateLogIfNeeded()

        // Write to file
        if let data = message.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                // Create new file
                try? data.write(to: logFileURL)
            }
        }
    }

    private func rotateLogIfNeeded() {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return
        }

        // Check file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
           let fileSize = attributes[.size] as? Int,
           fileSize > maxLogSize {

            // Move current log to .old
            let oldLogURL = logDirectory.appendingPathComponent("tibok.log.old")
            try? FileManager.default.removeItem(at: oldLogURL)
            try? FileManager.default.moveItem(at: logFileURL, to: oldLogURL)
        }
    }
}
