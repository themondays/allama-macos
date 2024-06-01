import SQLite
import Foundation

class DatabaseHelper {
    static let shared = DatabaseHelper()
    private var db: Connection?
    private let chats = Table("chats")
    private let id = Expression<Int64>("id")
    private let chatId = Expression<String>("chatId")
    private let message = Expression<String>("message")
    private let role = Expression<String>("role")
    private let timestamp = Expression<String>("timestamp")
    private let model = Expression<String>("model")
    private let chatNamesTable = Table("chatNames")
    private let chatNameId = Expression<String>("chatNameId")
    private let chatName = Expression<String>("chatName")

    private init() {
        let fileManager = FileManager.default
        let documentDirectory: URL

        do {
            documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let databaseURL = documentDirectory.appendingPathComponent("allamachats.sqlite3")
            db = try Connection(databaseURL.path)
            try createTables()
        } catch {
            db = nil
            print("Unable to open database: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }
        try db.run(chats.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(chatId)
            table.column(message)
            table.column(role)
            table.column(timestamp)
            table.column(model)
        })
        try db.run(chatNamesTable.create(ifNotExists: true) { table in
            table.column(chatNameId, primaryKey: true)
            table.column(chatName)
        })
    }

    func addMessage(chatId: String, message: String, role: String, timestamp: String, model: String) {
        guard let db = db else { return }
        do {
            let insert = chats.insert(self.chatId <- chatId, self.message <- message, self.role <- role, self.timestamp <- timestamp, self.model <- model)
            try db.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }

    func fetchMessages(forChatId chatId: String) -> [String] {
        guard let db = db else { return [] }
        var messages: [String] = []
        do {
            for chat in try db.prepare(chats.filter(self.chatId == chatId)) {
                var messageLine = "[\(chat[self.role])] \(chat[self.message])"
                if chat[self.role] == "assistant" {
                    messageLine += "\n\n\(chat[self.model])@\(chat[self.timestamp])"
                }
                messages.append(messageLine)
            }
        } catch {
            print("Select failed: \(error)")
        }
        return messages
    }

    func removeMessages(forChatId chatId: String) {
        guard let db = db else { return }
        do {
            let chatMessages = chats.filter(self.chatId == chatId)
            try db.run(chatMessages.delete())
        } catch {
            print("Delete failed: \(error)")
        }
    }

    func addChatName(id: String, name: String) {
        guard let db = db else { return }
        do {
            let insert = chatNamesTable.insert(self.chatNameId <- id, self.chatName <- name)
            try db.run(insert)
        } catch {
            print("Insert chat name failed: \(error)")
        }
    }

    func fetchChatNames() -> [(String, String)] {
        guard let db = db else { return [] }
        var names: [(String, String)] = []
        do {
            for chatName in try db.prepare(chatNamesTable) {
                names.append((chatName[self.chatNameId], chatName[self.chatName]))
            }
        } catch {
            print("Select chat names failed: \(error)")
        }
        return names
    }

    func updateChatName(id: String, name: String) {
        guard let db = db else { return }
        let chatToUpdate = chatNamesTable.filter(chatNameId == id)
        do {
            try db.run(chatToUpdate.update(chatName <- name))
        } catch {
            print("Update chat name failed: \(error)")
        }
    }

    func removeChatName(id: String) {
        guard let db = db else { return }
        do {
            let chatNameToDelete = chatNamesTable.filter(self.chatNameId == id)
            try db.run(chatNameToDelete.delete())
        } catch {
            print("Delete chat name failed: \(error)")
        }
    }
}
