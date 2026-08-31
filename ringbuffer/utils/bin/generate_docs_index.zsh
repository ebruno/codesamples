#!/usr/bin/env zsh
# Generate docs/index.html with links to available language documentation

set -euo pipefail

DOCS_BASE="docs/ringbuffer"
OUTPUT="${DOCS_BASE}/index.html"

# Build language cards dynamically based on what exists
LANG_CARDS=""

if [ -f "${DOCS_BASE}/cpp/html/index.html" ]; then
    LANG_CARDS="${LANG_CARDS}
    <div class=\"lang-card\">
        <h2>C++</h2>
        <p>Complete API reference with class hierarchies, enum documentation, and architecture diagrams.</p>
        <a href=\"cpp/html/index.html\">View C++ Documentation →</a>
    </div>"
fi

if [ -f "${DOCS_BASE}/java/html/index.html" ]; then
    LANG_CARDS="${LANG_CARDS}
    <div class=\"lang-card\">
        <h2>Java</h2>
        <p>Full API reference with package documentation, enum descriptions, and class diagrams.</p>
        <a href=\"java/html/index.html\">View Java Documentation →</a>
    </div>"
fi

if [ -f "${DOCS_BASE}/python/breathe-html/index.html" ]; then
    LANG_CARDS="${LANG_CARDS}
    <div class=\"lang-card\">
        <h2>Python (Breathe)</h2>
        <p>API reference generated from Doxygen XML via Breathe — includes full class/function documentation.</p>
        <a href=\"python/breathe-html/index.html\">View Python (Breathe) Documentation →</a>
    </div>"
fi

if [ -f "${DOCS_BASE}/python/sphinx-html/index.html" ]; then
    LANG_CARDS="${LANG_CARDS}
    <div class=\"lang-card\">
        <h2>Python (Sphinx)</h2>
        <p>API reference generated from Python docstrings via Sphinx autodoc/napoleon — no Doxygen dependency.</p>
        <a href=\"python/sphinx-html/index.html\">View Python (Sphinx) Documentation →</a>
    </div>"
fi

# If no docs found, generate a placeholder
if [ -z "${LANG_CARDS}" ]; then
    LANG_CARDS="
    <div class=\"lang-card\">
        <h2>No Documentation Available</h2>
        <p>Run <code>make create-doc</code> to generate documentation first.</p>
    </div>"
fi

# Write the index page
cat > "${OUTPUT}" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ringbuffer Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #333; }
        h1 { border-bottom: 2px solid #0366d6; padding-bottom: 10px; }
        .lang-card { border: 1px solid #e1e4e8; border-radius: 6px; padding: 20px; margin: 16px 0; }
        .lang-card h2 { margin-top: 0; color: #0366d6; }
        .lang-card a { display: inline-block; background: #0366d6; color: white; padding: 8px 16px; border-radius: 4px; text-decoration: none; }
        .lang-card a:hover { background: #0256b9; }
    </style>
</head>
<body>
    <h1>Ringbuffer Documentation</h1>
    <p>High-performance, cross-platform circular buffer library with pipelined Read→Transform→Write architecture.</p>

${LANG_CARDS}

    <hr>
    <p><small>Built with Doxygen + Breathe. Run <code>make create-doc</code> to regenerate.</small></p>
</body>
</html>
EOF

echo "Docs index generated at ${OUTPUT}"
