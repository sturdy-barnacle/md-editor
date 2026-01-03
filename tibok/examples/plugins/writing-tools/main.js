// ============================================
// Writing Tools Plugin - Minimal Test Version
// ============================================
// Simplified to debug plugin loading issues.
// Check Console.app for "[com.example.writing-tools]" logs.

tibok.log.info("=== Writing Tools plugin starting ===");

// ONE slash command with static insert (no JS execution needed)
tibok.slashCommands.register({
    name: "sig",
    description: "Insert author signature",
    icon: "signature",
    insert: "\n-- Written with Tibok --\n"
});
tibok.log.info("Registered /sig slash command");

// ONE command with simple action
tibok.commands.register({
    id: "hello",
    title: "Say Hello",
    subtitle: "Test plugin command",
    category: "general",
    action: function() {
        tibok.log.info("Hello command executed!");
        tibok.editor.insertText("Hello from Writing Tools plugin!");
    }
});
tibok.log.info("Registered 'Say Hello' command");

tibok.log.info("=== Writing Tools plugin loaded successfully ===");
