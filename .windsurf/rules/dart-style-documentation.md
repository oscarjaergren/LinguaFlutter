---
description: 'Dart style and documentation guidelines following official recommendations.'
applyTo: '**/*.dart'
---

# Dart Style & Documentation

Best practices recommended by the Dart team for code style and documentation. These instructions were taken from [Effective Dart](https://dart.dev/effective-dart).

## Effective Dart Overview

Over the past several years, we've written a ton of Dart code and learned a lot about what works well and what doesn't. We're sharing this with you so you can write consistent, robust, fast code too. There are two overarching themes:

1.  **Be consistent.** When it comes to things like formatting, and casing, arguments about which is better are subjective and impossible to resolve. What we do know is that being *consistent* is objectively helpful.

    If two pieces of code look different it should be because they *are* different in some meaningful way. When a bit of code stands out and catches your eye, it should do so for a useful reason.

2.  **Be brief.** Dart was designed to be familiar, so it inherits many of the same statements and expressions as C, Java, JavaScript and other languages. But we created Dart because there is a lot of room to improve on what those languages offer. We added a bunch of features, from string interpolation to initializing formals, to help you express your intent more simply and easily.

    If there are multiple ways to say something, you should generally pick the most concise one. This is not to say you should `code golf` yourself into cramming a whole program into a single line. The goal is code that is *economical*, not *dense*.

## Guidelines Format

Each guideline starts with one of these words:

*   **DO** guidelines describe practices that should always be followed. There will almost never be a valid reason to stray from them.
*   **DON'T** guidelines are the converse: things that are almost never a good idea.
*   **PREFER** guidelines are practices that you *should* follow. However, there may be circumstances where it makes sense to do otherwise.
*   **AVOID** guidelines are the dual to "prefer": stuff you shouldn't do but where there may be good reasons to on rare occasions.
*   **CONSIDER** guidelines are practices that you might or might not want to follow, depending on circumstances, precedents, and your own preference.

## Style Rules

### Identifiers

*   DO name types using `UpperCamelCase`.
*   DO name extensions using `UpperCamelCase`.
*   DO name packages, directories, and source files using `lowercase_with_underscores`.
*   DO name import prefixes using `lowercase_with_underscores`.
*   DO name other identifiers using `lowerCamelCase`.
*   PREFER using `lowerCamelCase` for constant names.
*   DO capitalize acronyms and abbreviations longer than two letters like words.
*   PREFER using wildcards for unused callback parameters.
*   DON'T use a leading underscore for identifiers that aren't private.
*   DON'T use prefix letters.
*   DON'T explicitly name libraries.

### Ordering

*   DO place `dart:` imports before other imports.
*   DO place `package:` imports before relative imports.
*   DO specify exports in a separate section after all imports.
*   DO sort sections alphabetically.

### Formatting

*   DO format your code using `dart format`.
*   CONSIDER changing your code to make it more formatter-friendly.
*   PREFER lines 80 characters or fewer.
*   DO use curly braces for all flow control statements.

## Documentation Rules

### Comments

*   DO format comments like sentences.
*   DON'T use block comments for documentation.

### Doc Comments

*   DO use `///` doc comments to document members and types.
*   PREFER writing doc comments for public APIs.
*   CONSIDER writing a library-level doc comment.
*   CONSIDER writing doc comments for private APIs.
*   DO start doc comments with a single-sentence summary.
*   DO separate the first sentence of a doc comment into its own paragraph.
*   AVOID redundancy with the surrounding context.
*   PREFER starting comments of a function or method with third-person verbs if its main purpose is a side effect.
*   PREFER starting a non-boolean variable or property comment with a noun phrase.
*   PREFER starting a boolean variable or property comment with "Whether" followed by a noun or gerund phrase.
*   PREFER a noun phrase or non-imperative verb phrase for a function or method if returning a value is its primary purpose.
*   DON'T write documentation for both the getter and setter of a property.
*   PREFER starting library or type comments with noun phrases.
*   CONSIDER including code samples in doc comments.
*   DO use square brackets in doc comments to refer to in-scope identifiers.
*   DO use prose to explain parameters, return values, and exceptions.
*   DO put doc comments before metadata annotations.

### Markdown

*   AVOID using markdown excessively.
*   AVOID using HTML for formatting.
*   PREFER backtick fences for code blocks.

### Writing

*   PREFER brevity.
*   AVOID abbreviations and acronyms unless they are obvious.
*   PREFER using "this" instead of "the" to refer to a member's instance.
