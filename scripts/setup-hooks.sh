#!/bin/sh
# Install git hooks from scripts/ into .git/hooks/
# Run once after cloning: sh scripts/setup-hooks.sh

HOOKS_DIR=".git/hooks"
SCRIPTS_DIR="scripts"

cp "$SCRIPTS_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks installed. dart format will run before every commit."
