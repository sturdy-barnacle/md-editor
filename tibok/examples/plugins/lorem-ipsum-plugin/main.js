/**
 * Lorem Ipsum Generator Plugin for Tibok
 *
 * This example plugin demonstrates:
 * - Registering slash commands
 * - Registering command palette commands
 * - Using the editor API to insert text
 * - Using the logging API
 */

// Lorem ipsum paragraphs
const LOREM_PARAGRAPHS = [
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",

    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",

    "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.",

    "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.",

    "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident."
];

/**
 * Generate lorem ipsum text
 * @param {number} paragraphs - Number of paragraphs to generate
 * @returns {string} Generated text
 */
function generateLorem(paragraphs) {
    const count = Math.max(1, Math.min(paragraphs, 10)); // Clamp 1-10
    const result = [];

    for (let i = 0; i < count; i++) {
        result.push(LOREM_PARAGRAPHS[i % LOREM_PARAGRAPHS.length]);
    }

    return result.join("\n\n");
}

// =============================================================================
// SLASH COMMANDS
// =============================================================================

// Basic lorem command - insert one paragraph
tibok.slashCommands.register({
    name: "lorem",
    description: "Insert a lorem ipsum paragraph",
    icon: "text.word.spacing",
    keywords: ["placeholder", "dummy", "text", "filler"],
    category: "general",
    execute: function(args) {
        const count = parseInt(args) || 1;
        const text = generateLorem(count);
        tibok.editor.insertText(text);
        tibok.log.info("Inserted " + count + " lorem ipsum paragraph(s)");
    }
});

// Quick shortcuts for common paragraph counts
tibok.slashCommands.register({
    name: "lorem3",
    description: "Insert 3 lorem ipsum paragraphs",
    icon: "text.word.spacing",
    keywords: ["placeholder", "dummy", "text"],
    category: "general",
    execute: function() {
        tibok.editor.insertText(generateLorem(3));
    }
});

tibok.slashCommands.register({
    name: "lorem5",
    description: "Insert 5 lorem ipsum paragraphs",
    icon: "text.word.spacing",
    keywords: ["placeholder", "dummy", "text"],
    category: "general",
    execute: function() {
        tibok.editor.insertText(generateLorem(5));
    }
});

// Short lorem - just one sentence
tibok.slashCommands.register({
    name: "loremshort",
    description: "Insert a short lorem ipsum sentence",
    icon: "text.cursor",
    keywords: ["placeholder", "short", "sentence"],
    category: "general",
    insert: "Lorem ipsum dolor sit amet."
});

// =============================================================================
// COMMAND PALETTE COMMANDS
// =============================================================================

tibok.commands.register({
    id: "insert-lorem-1",
    title: "Insert Lorem Ipsum (1 paragraph)",
    subtitle: "Insert placeholder text",
    icon: "text.word.spacing",
    category: "insert",
    action: function() {
        tibok.editor.insertText(generateLorem(1));
    }
});

tibok.commands.register({
    id: "insert-lorem-3",
    title: "Insert Lorem Ipsum (3 paragraphs)",
    subtitle: "Insert placeholder text",
    icon: "text.word.spacing",
    category: "insert",
    action: function() {
        tibok.editor.insertText(generateLorem(3));
    }
});

tibok.commands.register({
    id: "insert-lorem-5",
    title: "Insert Lorem Ipsum (5 paragraphs)",
    subtitle: "Insert placeholder text",
    icon: "text.word.spacing",
    category: "insert",
    action: function() {
        tibok.editor.insertText(generateLorem(5));
    }
});

// =============================================================================
// INITIALIZATION
// =============================================================================

tibok.log.info("Lorem Ipsum Generator plugin loaded successfully!");
tibok.log.info("Available commands: /lorem, /lorem3, /lorem5, /loremshort");
