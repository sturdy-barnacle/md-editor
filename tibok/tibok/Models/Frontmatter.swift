//
//  Frontmatter.swift
//  tibok
//
//  Parses and generates Jekyll/Hugo frontmatter (YAML and TOML).
//

import Foundation

// MARK: - Frontmatter Format

enum FrontmatterFormat: String, CaseIterable {
    case yaml   // Jekyll/Hugo YAML (---)
    case toml   // Hugo TOML (+++)
    case none

    var delimiter: String {
        switch self {
        case .yaml: return "---"
        case .toml: return "+++"
        case .none: return ""
        }
    }
}

// MARK: - Frontmatter Value

enum FrontmatterValue: Equatable {
    case string(String)
    case bool(Bool)
    case date(Date)
    case array([String])
    case number(Double)

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    var dateValue: Date? {
        if case .date(let d) = self { return d }
        return nil
    }

    var arrayValue: [String]? {
        if case .array(let a) = self { return a }
        return nil
    }

    var numberValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }
}

// MARK: - Frontmatter

struct Frontmatter {
    var format: FrontmatterFormat
    var fields: [String: FrontmatterValue]
    var rawString: String
    var includeDateWithTime: Bool = false  // Whether to include time when formatting date
    var timezoneIdentifier: String = ""    // Timezone for date formatting (empty = system default)

    // MARK: - Common Fields (convenience accessors)

    var title: String? {
        get { fields["title"]?.stringValue }
        set { fields["title"] = newValue.map { .string($0) } }
    }

    var date: Date? {
        get { fields["date"]?.dateValue }
        set { fields["date"] = newValue.map { .date($0) } }
    }

    var tags: [String] {
        get { fields["tags"]?.arrayValue ?? [] }
        set { fields["tags"] = .array(newValue) }
    }

    var categories: [String] {
        get { fields["categories"]?.arrayValue ?? [] }
        set { fields["categories"] = .array(newValue) }
    }

    var layout: String? {
        get { fields["layout"]?.stringValue }
        set { fields["layout"] = newValue.map { .string($0) } }
    }

    var draft: Bool {
        get { fields["draft"]?.boolValue ?? false }
        set { fields["draft"] = .bool(newValue) }
    }

    var author: String? {
        get { fields["author"]?.stringValue }
        set { fields["author"] = newValue.map { .string($0) } }
    }

    var description: String? {
        get { fields["description"]?.stringValue }
        set { fields["description"] = newValue.map { .string($0) } }
    }

    // MARK: - Initialization

    init(format: FrontmatterFormat = .yaml, fields: [String: FrontmatterValue] = [:], rawString: String = "") {
        self.format = format
        self.fields = fields
        self.rawString = rawString
    }

    // MARK: - Parsing

    /// Parse frontmatter from markdown content.
    /// Returns the parsed frontmatter (if any) and the body content without frontmatter.
    static func parse(from content: String) -> (frontmatter: Frontmatter?, body: String) {
        let trimmed = content.trimmingCharacters(in: .whitespaces)

        // Try YAML (---)
        if trimmed.hasPrefix("---") {
            if let result = parseDelimited(content: content, delimiter: "---", format: .yaml) {
                return result
            }
        }

        // Try TOML (+++)
        if trimmed.hasPrefix("+++") {
            if let result = parseDelimited(content: content, delimiter: "+++", format: .toml) {
                return result
            }
        }

        // No frontmatter
        return (nil, content)
    }

    private static func parseDelimited(content: String, delimiter: String, format: FrontmatterFormat) -> (frontmatter: Frontmatter?, body: String)? {
        let lines = content.components(separatedBy: .newlines)

        // Find opening delimiter
        guard let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
              firstLine == delimiter else {
            return nil
        }

        // Find closing delimiter
        var closingIndex: Int?
        for (index, line) in lines.enumerated() where index > 0 {
            if line.trimmingCharacters(in: .whitespaces) == delimiter {
                closingIndex = index
                break
            }
        }

        guard let endIndex = closingIndex else {
            return nil // No closing delimiter
        }

        // Extract frontmatter content
        let frontmatterLines = lines[1..<endIndex]
        let rawString = frontmatterLines.joined(separator: "\n")

        // Extract body (everything after closing delimiter)
        let bodyLines = lines[(endIndex + 1)...]
        let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .newlines)

        // Parse fields based on format
        let fields: [String: FrontmatterValue]
        switch format {
        case .yaml:
            fields = parseYAML(rawString)
        case .toml:
            fields = parseTOML(rawString)
        case .none:
            fields = [:]
        }

        let frontmatter = Frontmatter(format: format, fields: fields, rawString: rawString)
        return (frontmatter, body)
    }

    // MARK: - YAML Parsing (simple implementation)

    private static func parseYAML(_ yaml: String) -> [String: FrontmatterValue] {
        var fields: [String: FrontmatterValue] = [:]
        let lines = yaml.components(separatedBy: .newlines)

        var currentKey: String?
        var arrayValues: [String] = []
        var inArray = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Array item (starts with -)
            if trimmed.hasPrefix("- ") && inArray && currentKey != nil {
                let value = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                arrayValues.append(value)
                continue
            }

            // Save previous array if we were collecting one
            if inArray, let key = currentKey, !arrayValues.isEmpty {
                fields[key] = .array(arrayValues)
                arrayValues = []
                inArray = false
            }

            // Key: value pair
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let valueStr = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                currentKey = key

                if valueStr.isEmpty {
                    // Could be an array starting on next line
                    inArray = true
                    arrayValues = []
                } else if valueStr.hasPrefix("[") && valueStr.hasSuffix("]") {
                    // Inline array: [tag1, tag2]
                    let inner = String(valueStr.dropFirst().dropLast())
                    let items = inner.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    fields[key] = .array(items)
                    inArray = false
                } else {
                    // Single value
                    fields[key] = parseYAMLValue(valueStr)
                    inArray = false
                }
            }
        }

        // Save final array if any
        if inArray, let key = currentKey, !arrayValues.isEmpty {
            fields[key] = .array(arrayValues)
        }

        return fields
    }

    private static func parseYAMLValue(_ value: String) -> FrontmatterValue {
        // Remove quotes if present
        var cleaned = value
        if (cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"")) ||
           (cleaned.hasPrefix("'") && cleaned.hasSuffix("'")) {
            cleaned = String(cleaned.dropFirst().dropLast())
            return .string(cleaned)
        }

        // Boolean
        if cleaned.lowercased() == "true" { return .bool(true) }
        if cleaned.lowercased() == "false" { return .bool(false) }

        // Date (ISO 8601 or common formats)
        if let date = parseDate(cleaned) {
            return .date(date)
        }

        // Number
        if let number = Double(cleaned) {
            return .number(number)
        }

        // Default to string
        return .string(cleaned)
    }

    // MARK: - TOML Parsing (simple implementation)

    private static func parseTOML(_ toml: String) -> [String: FrontmatterValue] {
        var fields: [String: FrontmatterValue] = [:]
        let lines = toml.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Key = value pair
            if let equalsIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalsIndex]).trimmingCharacters(in: .whitespaces)
                let valueStr = String(trimmed[trimmed.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)

                fields[key] = parseTOMLValue(valueStr)
            }
        }

        return fields
    }

    private static func parseTOMLValue(_ value: String) -> FrontmatterValue {
        var cleaned = value

        // String (double quotes)
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
            return .string(cleaned)
        }

        // Array
        if cleaned.hasPrefix("[") && cleaned.hasSuffix("]") {
            let inner = String(cleaned.dropFirst().dropLast())
            let items = inner.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { item -> String in
                    var s = item
                    if (s.hasPrefix("\"") && s.hasSuffix("\"")) {
                        s = String(s.dropFirst().dropLast())
                    }
                    return s
                }
            return .array(items)
        }

        // Boolean
        if cleaned.lowercased() == "true" { return .bool(true) }
        if cleaned.lowercased() == "false" { return .bool(false) }

        // Date
        if let date = parseDate(cleaned) {
            return .date(date)
        }

        // Number
        if let number = Double(cleaned) {
            return .number(number)
        }

        return .string(cleaned)
    }

    // MARK: - Date Parsing

    private static func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = [
                "yyyy-MM-dd",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        // Try ISO8601DateFormatter
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }

    // MARK: - Serialization

    /// Convert frontmatter back to string representation.
    func toString() -> String {
        switch format {
        case .yaml:
            return toYAMLString()
        case .toml:
            return toTOMLString()
        case .none:
            return ""
        }
    }

    private func toYAMLString() -> String {
        var lines: [String] = ["---"]

        // Write fields in a consistent order
        let orderedKeys = ["title", "date", "author", "layout", "draft", "description", "tags", "categories"]
        var writtenKeys = Set<String>()

        // Write ordered keys first
        for key in orderedKeys {
            if let value = fields[key] {
                lines.append(formatYAMLField(key: key, value: value))
                writtenKeys.insert(key)
            }
        }

        // Write remaining custom fields
        for (key, value) in fields where !writtenKeys.contains(key) {
            lines.append(formatYAMLField(key: key, value: value))
        }

        lines.append("---")
        return lines.joined(separator: "\n")
    }

    private func formatYAMLField(key: String, value: FrontmatterValue) -> String {
        switch value {
        case .string(let s):
            // Quote if contains special characters
            if s.contains(":") || s.contains("#") || s.contains("\"") || s.hasPrefix(" ") {
                return "\(key): \"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
            }
            return "\(key): \(s)"
        case .bool(let b):
            return "\(key): \(b)"
        case .date(let d):
            return "\(key): \(formatDateString(d))"
        case .array(let arr):
            if arr.isEmpty { return "\(key): []" }
            return "\(key): [\(arr.joined(separator: ", "))]"
        case .number(let n):
            if n == floor(n) {
                return "\(key): \(Int(n))"
            }
            return "\(key): \(n)"
        }
    }

    private func toTOMLString() -> String {
        var lines: [String] = ["+++"]

        // Write fields in a consistent order
        let orderedKeys = ["title", "date", "author", "layout", "draft", "description", "tags", "categories"]
        var writtenKeys = Set<String>()

        for key in orderedKeys {
            if let value = fields[key] {
                lines.append(formatTOMLField(key: key, value: value))
                writtenKeys.insert(key)
            }
        }

        for (key, value) in fields where !writtenKeys.contains(key) {
            lines.append(formatTOMLField(key: key, value: value))
        }

        lines.append("+++")
        return lines.joined(separator: "\n")
    }

    private func formatTOMLField(key: String, value: FrontmatterValue) -> String {
        switch value {
        case .string(let s):
            return "\(key) = \"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
        case .bool(let b):
            return "\(key) = \(b)"
        case .date(let d):
            return "\(key) = \(formatDateString(d))"
        case .array(let arr):
            let quoted = arr.map { "\"\($0)\"" }
            return "\(key) = [\(quoted.joined(separator: ", "))]"
        case .number(let n):
            if n == floor(n) {
                return "\(key) = \(Int(n))"
            }
            return "\(key) = \(n)"
        }
    }

    // MARK: - Date Formatting

    /// Format a date with timezone support.
    /// Returns ISO 8601 format when time is included, simple date otherwise.
    private func formatDateString(_ date: Date) -> String {
        let tz: TimeZone
        if !timezoneIdentifier.isEmpty, let customTZ = TimeZone(identifier: timezoneIdentifier) {
            tz = customTZ
        } else {
            tz = TimeZone.current
        }

        if includeDateWithTime {
            // Full ISO 8601 with timezone: 2025-01-15T10:30:00+08:00
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            formatter.timeZone = tz
            return formatter.string(from: date)
        } else {
            // Date only: 2025-01-15
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = tz
            return formatter.string(from: date)
        }
    }

    // MARK: - Document Integration

    /// Update document content with modified frontmatter.
    func apply(to content: String) -> String {
        let (_, body) = Frontmatter.parse(from: content)
        let frontmatterStr = toString()

        if frontmatterStr.isEmpty {
            return body
        }

        return "\(frontmatterStr)\n\n\(body)"
    }

    /// Create a new document with this frontmatter.
    static func createDocument(frontmatter: Frontmatter, body: String) -> String {
        let frontmatterStr = frontmatter.toString()
        if frontmatterStr.isEmpty {
            return body
        }
        return "\(frontmatterStr)\n\n\(body)"
    }
}
