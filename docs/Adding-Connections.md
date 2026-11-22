---
layout: default
title: Connections
parent: Creating a Mind Map
nav_order: 6
---

# Connections

A mind map tree shows the relationships between an idea and subideas using a parent/child relationship; however, sometimes it is useful to show a connection between two ideas that do not share this relationship. For this reason, Minder supports creating a connection between any two nodes in the mind map.

## Creating a Connection with the Mouse

To create a connection using your mouse or trackpad, select an existing node in the tree by left-clicking on the node and then display the contextual menu for the node using a right-click on the mouse.  Select the **Add Connection** menu item. This will close the contextual menu and begin to draw a connection from the currently selected node to the location of the cursor.  To complete the connection, move the mouse cursor over the node to connect to (the node will be highlighted to let you know that it is connectable) and left-click on the node.  This will complete the connection and immediately select it. If the left-mouse button is clicked when the mouse cursor is not over a node or the **Escape** key is pressed, the connection will be removed and the previously selected node will be reselected.

## Creating a Connection with the Keyboard

It is also possible to create a connection between two nodes using only the keyboard.  To do this, select a node to create an attachment to using the selection navigation keys.  Start the connection by pressing the **&gt;** character. This will begin a connection starting at the currently selected node and will highlight the current node.  After this has been done, using the selection navigation keys to choose the second node to connect to.  The "to" node will be highlighted as you move around the mind map.  To complete the connection, hit the **Return** key.  This will draw the connection and immediately select it.  If the **Escape** key is pressed instead of the **Return** key, the connection will be removed and the previously selected node will be reselected.

## Deleting a Connection

To delete any connection, select the connection by left-clicking on it and press the **Delete** or **Backspace** keys. You can also delete the connection by bringing up the contextual menu and selecting the **Delete Connection** menu item. Deleting a connection will only delete the selected connection.  The nodes attached to the connection will remain intact.

### What happens to a connection when an attached node is deleted?

If one or both of the nodes that a connection is attached to is deleted, the connection will also be deleted. Connections must be attached to two nodes in the mind-map to exist.

## Changing the Shape of the Connection

By default, when a connection is drawn it will be straight line between the attached nodes; however, when the connection is selected, three drag points are drawn on the connection. By clicking and dragging the center point around the canvas, you can curve the connection to improve the readability of the mind-map. When the center point is dragged, the ends of the connection will automatically point themselves to the center of the attached nodes.

## Changing the Connection

If you need to keep a connection but change which two nodes it is connected to, you can do that by selecting the connection and then clicking and dragging one of the two endpoint drag handles to the new node. Once the endpoint is over the new node, simply release the drag to complete the connection. If the mouse button is released when the endpoint is not over a node or the **Escape** key is pressed while the connection is being dragged, the connection will reattach to the previously connected nodes and remain in the canvas.

## Adding a Title

By default, when a connection is created, the connection will only show a line connecting to two nodes with an arrow draw on the "to" side of the connection. However, you may want to add some displayed text to the connection to help identify the relation between the two ideas.

To add a title to the connection, select the connection, right-click on the canvas to display the contextual menu and select the "Edit..." option.  This will draw an empty title on the connection with an insertion cursor drawn.  Simply enter the title text, pressing the **Return** key to complete the edit.

To edit an existing connection title, either double-click the connection title or select the connection and select the "Edit..." option in the contextual menu or press the **E** key. When a connection title is editable, the text will be selected and the insertion cursor will be displayed.

To remove an existing connection title, edit the connection text as described above and then remove all text in the title, followed by pressing the **Return** key. If a connection's title contains no text, it will be removed from the connection in the mind-map canvas.

## Adding a Note

Like nodes, connections can also store additional information about themselves in the form of a note.  Note text is not displayed in the canvas but can be viewed/edited in the [Connection Sidebar](Connection-Sidebar.md).  Any changes to the note will be immediately saved to file.  Note text is searchable via the header bar search function.

## Styling a Connection

To change the styling of the connection, select the connection, show the property sidebar and select the **Style** tab. Things like the thickness of the connection line, arrow options, the style of the connection line and the connection text font can be changed within this panel.

## Navigating from the Connection to one of the Attached Nodes

If a connection is currently selected, you can quickly select either the "from" node or the "to" node by pressing the **P** or **N** keys, respectively. Alternatively, you can bring up the contextual menu for the connection and select one of the selection menu items from there.

## Alternative Uses for Connections

Though mind maps are traditionally a tree-like structure, it is possible to create different structures in Minder using connections.  For example, you could create a flow charts or digraphs by creating root nodes and attaching those nodes with connections, using arrows on the connections to denote direction or flow to the diagram. It is also possible to attach two or more connections between the same nodes, meaning that you could draw things like sequences between two or more entities. Your thought process is the limit!
