---
layout: default
title: Adding Tables
parent: Creating a Mind Map
nav_order: 10
has_children: true
has_toc: false
---

# Tables

Minder supports creating a table that is displayed in a node.  Only one table per node is supported.  Table cells can contain only text (Markdown not currently supported) with the exception of unicode characters, emoji, and inline LaTeX using the same `$$...$$` delimiters as that allowed in node text.

## Adding a Table

To add a table to a node, select a node, right-click to show the contextual menu, and choose `Change Node → Add Table…`.  This will display an editable table inside it.  To edit an existing table, double-click the node table.  Either action will display the table editor popup.  After editing the resulting table, click the **Apply** button to end table editing mode and apply the changes.  Click on the **Cancel** button to end table edit mode without applying any changes made within the editor.

Enter text directly into cells.  Editors expand and wrap while you type so longer and multiline content remains visible.

To keep the editor responsive, imported and pasted tables are limited to 100 rows, 50 columns, and 1,000 cells.

## Removing a Table

To remove an existing table within a node, double-click the table and click on the **Delete Table** button in the table editor bottom button bar.  This will end table editing mode and remove the table from the current node.

See [table editor](Table-Editor.md) for more details on the table editing interface.

