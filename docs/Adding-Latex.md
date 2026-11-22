---
layout: default
title: Adding Embedded LaTeX
parent: Creating a Mind Map
nav_order: 9
---

# Embedded LaTeX

In addition to Markdown text, node, connection and callout text can also include embedded LaTeX mathematical formulas and other typeset.  To typeset a formula, surround it with standard `$...$` or `$$...$$` inline delimiters.  Formulas can be mixed with ordinary text and more than one can be used in a text value.  For example:

```latex
This is a formula $$\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$
```

Minder displays the source while it is being edited.  When editing finishes, each formula is drawn as an inline scalable SVG.  If the LaTeX tools are unavailable or an expression is invalid, Minder leaves that source visible. Use `\$` for a
literal dollar sign when needed; the escape is hidden when editing finishes.

## Pasting Formulas From Images

If the optional `formulaocr-offline` command is installed, pasting a formula image with **Control+Shift+V** converts it locally to editable `$$...$$` source and then renders it as SVG.  Ordinary **Ctrl+V** keeps its usual behavior, including pasting clipboard images as images.  Recognition is asynchronous and does not require an internet connection.  Set the `MINDER_FORMULA_OCR` environment variable to select a different local recognizer executable.
