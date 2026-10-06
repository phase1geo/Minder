This is the main area below the header bar where the user can create, edit, view and rearrange mind map nodes.

The following is a representation of this area.

![Mind Map Canvas](https://github.com/phase1geo/Minder/wiki/images/canvas.png)

### Navigating the Canvas

* To pan the contents of the canvas, hold down the Alt key while moving the mouse cursor.
* To scroll up/down with a mouse, use the scrollwheel.  To scroll left/right with a mouse, hold down the Shift key while using the scrollwheel.
* To draw a selection box around nodes, click anywhere on the canvas that is not occupied by an element and press the left mouse button while moving the mouse cursor.
* To select a node, simply click on any node in the canvas. This will cause the node to be drawn with a selection around the entire node's contents and will make this node the "current" node. Any actions selected in the contextual menu will be applied to this node. To deselect the node, simply click on any space in the canvas not occupied by a node.
* To edit the text within a node, double click on the text area of the node. This will cause the entire text of the node to be selected and the cursor will be drawn.

### Editing Node Text

* When node text is in edit mode (by double-clicking on the node text in the canvas), all text will be selected, allowing you to start entering new text for the node.

### Canvas Contextual Menu

By right-clicking anywhere in the canvas, you can bring up a contextual menu that provides an extensive list of functionality to use within the canvas.

INSERT IMAGE

The following table summarizes each option in this menu.

| Option | Keyboard Shortcut | Description |
|--------|-------------------|-------------|
| Copy | Control-C | Copies the currently selected node and its descendants. |
| Cut | Control-X | Copies the currently selected node and its descendants and deletes them from the canvas. |
| Paste | Control-V | Copies previously copied node tree as a child of the currently selected node. |
| Delete | Delete | Removes the currently selected node and its descendants from the canvas. |
| Edit... | E | Displays the currently selected node within the sidebar which allows all of the node information to be changed. |
| Add Task | | This item will be displayed if the currently selected node is not already a task. Selecting this option will make the current node a task and will cause all parent nodes to display node tasks under them. |
| Remove Task | | This item will be displayed if the currently selected node is already a task. Selecting this option will remove the task identifier from the current node and adjust all parent nodes accordingly. |
| Add Note | | Displays the node note field in the sidebar, giving it immediate input focus. |
| Add Image | | This item is displayed if the currently selected node does not have an image associated with it. Displays an open file dialog to allow you to select any image from the file system to associate with the currently selected node. |
| Remove Image | | This item is displayed if the currently selected node already has an image associated with it. Selecting this option will remove the image from the current node. |
| Fold Children | F | This item is displayed if the currently selected node does not have its descendant nodes folded. Selecting this option will hide the descendant nodes of the currently selected node from view, replacing them with a small rectangular box with two dots in it. |
| Unfold Children | F | This item is displayed if the currently selected node already has its descendant nodes folded. Selecting this option will redisplay the descendant nodes of the current node. |
| Add Root Node |  | Adds a new root node to the canvas and allows the node text to be immediately edited. |
| Add Child Node | Tab | Adds a new node as a child of the currently selected node, making the node text immediately editable. |
| Add Sibling Node | Return | Adds a new node as a sibling of the currently selected node, making the node text immediately editable. |
| Select Node / Root | M | Selects the root node of the current node. If no node is currently selected, the root node of the first tree will be selected. |
| Select Node / Next Sibling | N | Selects the next sibling node of the current node. |
| Select Node / Previous Sibling | P | Selects the previous sibling node of the current node. |
| Select Node / First Child | C | Selects the first child node of the current node. |
| Select Node / Parent | A | Selects the parent node of te current node. |
| Center Current Node | Shift-C | Causes the mind-map to be panned such that the current node is centered within the canvas for better focus. |
| Detach | | Detaches the current node and its descendants from its parent node, making current node a root node of its own tree. |
