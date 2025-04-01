#!/bin/bash

# Define the Git hook path
HOOK_PATH=".git/hooks/post-checkout"

# Ensure the hooks directory exists
mkdir -p "$(dirname "$HOOK_PATH")"

# Write the hook script
cat > "$HOOK_PATH" << 'EOF'
#!/bin/bash

# Run the media processing script
bash collect_media.sh
EOF

# Make the hook executable
chmod +x "$HOOK_PATH"

echo "Git post-checkout hook installed successfully."
