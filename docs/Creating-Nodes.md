---
layout: default
title: Adding Nodes
parent: Creating a Mind Map
nav_order: 1
---

# Adding Nodes

A node in a mind-map represents an idea.  Nodes are arranged in a tree-like structure such that each tree contains a single, high-level idea at the top-level of the tree.  The next level of nodes in the tree are sub-ideas of the main idea and are related to the main idea via a "link".  Nodes at the same level are also known as "sibling" nodes in the tree.  Nodes can continuously be added to the tree at any level of the tree, helping to gain greater understanding of the main idea.

The node representing the main idea of the tree is also known as the "root" node.  All nodes closer to the root of the tree from any given nodes are also known as "ancestors" of that node.  All nodes that are further away from the root from any given node is also known as "descendants" of that node.  The node immediately linked to a node that is closer to the root is known as the "parent" of the node while any immediately linked node that is further from the root is known as a "child" of the node.

Each node in minder is capable of displaying/storing the following information:

1. A piece of text describing the idea.
2. [Images](Adding-Images.md) which are directly displayed inside of the node.
3. Any node can be represented as a [task](Adding-Tasks.md) which will draw a clickable checkbutton within the node, allowing you to track completion status within a mind-map.
4. Additional text in the form of a [note](Adding-Notes.md).

#### Creating a Node

When a new mind-map is created, Minder automatically creates a single node for the main idea of the mind map, placing that node in edit mode which allows you to immediately begin typing the text displayed in the main node.

**Note:** Whenever a new node is added, it is immediately placed into edit mode to make entering new ideas go as fast as possible.

##### Creating a New Root Node

To create another root node in the canvas, either select an existing root node and press the **Return** key to create a "sibling" of the root node (which is another root node).  Additionally, you can right-click to display the contextual menu and choose the **Add Root Node** menu option.

##### Creating a New Child Node

To create new child of a node, select that node and press the **Tab** key.  Alternatively, you can use the contextual menu and choose the **Add Child Node** menu option.

##### Creating a New Sibling Node

To create a new sibling for a given node, select that node and press the **Return** Key.  Alternatively, you can use the contextual menu and choose the **Add Sibling Node** menu option.

#### Deleting a Node

Whenever a node is deleted, it along with all of its descendants and any [connections](Adding-Connections.md) attached to it or its descendants are also deleted.  To delete a node, select it and press either the **Delete** or **Backspace** keys.  Alternatively, you can delete a node through both the contextual menu as well as within the [Node Sidebar](Node-Sidebar.md).

#### Selecting a Node

To operate on a specific node or view its content within the sidebar, that node must first be selected.  You can do this using either the mouse or the keyboard.

##### Selecting a Node with the Mouse/Trackpad

To select any node within the mind-map, simply locate it and left-click on it with the mouse.  When a node is selected, it will be specially highlighted to alert you that the node is selected. You can select more than one node by holding the **Shift** key while clicking nodes. Additionally, you can select nodes by clicking anywhere on the mindmap that is empty space and then left-click and drag out a rectangle selection box over the nodes to select.

##### Selecting a Node with the Keyboard

The following table lists the various keyboard keys that can be used to navigate around the mind-map, selecting a new node.

| Key     | Description                                                                                                                                                                                                                                                                              |
| ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| m       | If no node is currently selected, selects the root node of the first node tree in the mind map.  If any node is currently selected, the root node of the current node tree will be selected.                                                                                             |
| c       | If a node is currently selected, selects the first child node of the current node.                                                                                                                                                                                                       |
| n       | If a node is currently selected, selects the next sibling node of the current node.                                                                                                                                                                                                      |
| p       | If a node is currently selected, selects the previous sibling node of the current node.                                                                                                                                                                                                  |
| a       | If a node is currently selected, selects the parent node of the current node.                                                                                                                                                                                                            |
| &rarr;  | If a node is currently selected, selects the node that is immediately to the right of this node. If this node is a child node of the selected node, either the first child will be selected (if we have never navigated to a child node before) or the last selected child of this node. |
| &larr;  | If a node is currently selected, selects the node that is immediately to the left of this node.  Same rule applies if the node to the left is a child node.                                                                                                                              |
| &uarr;  | If a node is currently selected, selects the node that is immediately above this node.  Same rule applies if the node above is a child node.                                                                                                                                             |
| &darr;  | If a node is currently selected, selects the node that is immediately below this node.  Same rule applies if the node below is a child node.                                                                                                                                             |
| d       | If a node is currently selected, deselects the current node and selects all of the current node's children.                                                                                                                                                                              |
| Shift+d | If a node is currently selected, adds the current node's children to the selection, keeping the current node selected as well.                                                                                                                                                           |

#### Detaching a Node

Sometimes it will be necessary to create a new tree in the mind-map from an existing descendant node within a tree. To accomplish this, Minder allows you to "detach" the node and its descendants from its current tree, creating a new tree. To detach a node, make sure the node is selected and right-click to display the contextual menu and select the **Detach Node** menu option.  Alternatively, you can detach a node within the [Node Sidebar](Node-Sidebar.md) from the button bar at the bottom of the panel.

#### Attaching a Node

Additionally, there may be the need to either attach a node tree to another existing node tree, or you may need to move a node from one spot in the tree to another spot in the tree. To create these connections, simply click and drag an existing node until the node is over the node to attach to (the node to attach to will be highlighted) and then release the left mouse button to change the attachment.  The moved node will detach itself from its current parent node and attach itself to the new parent node.

#### Attaching Multiple Nodes

If more than one node is selected, Minder allows you to move only the selected nodes (i.e., not their subtrees) to a node where the selected nodes will be added to the attached node as siblings (regardless of their original relationship to each other). When this attachment occurs, the previous children nodes of their moved parent will attach themselves to the moved parent's original parent node. 

#### Copy, Cut and Paste a Node

Nodes can be copied, cut and/or pasted into a mind map.  The copied node is placed into a special, system-wide clipboard that is only recognized by Minder, meaning that if you copy a node and attempt to paste it into another application, nothing will occur.  When you copy a node, you are also copying the node's descendant nodes and any connections that are attached to nodes within the copied tree.

To copy or cut a node, make sure that it is selected and use the ubiquitous Control-c (copy) or Control-x (cut) keyboard shortcut.  Alternatively, you perform these actions with either the contextual menu or the [Node Sidebar](Node-Sidebar.md) button bar.

#### Editing the Node Title

To change the node's title text in the canvas, either double-click on the node with left mouse button or select the node and press the **e** key to begin the editing process.  When a node's title is editable, the text will be selected and the insertion cursor will be displayed within the text area.  Text editing, navigation and selection is performed using all of the standard editing capabilities for a text field within Gtk applications. To complete editing a node's title, press the **Return** key or **Escape** key.  This will exit editing mode for the node and return it to the selected state.
