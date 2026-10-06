To view functionality and information about the currently selected node, select the **Node** tab at the top of the sidebar. This will allow you to quickly change any of the node properties for the currently selected node as well as access quick functions for the current node. All changes made in this panel will be immediately and automatically saved to the current document.

The following is a representation of this panel:

![Node Sidebar Property Panel](https://github.com/phase1geo/Minder/wiki/images/node-property-panel.png)

<u>Important Note:</u> If a node is not currently selected this panel will be blank.

#### Title

The _Title_ field allows the text that is displayed in the node in the canvas to be changed. To edit, simply select text or insert the cursor at the desired location and type. You can insert any of the system emoji in this text field by using Control-. (period) and selecting any of the available emoji in the window.

#### Task

The _Task_ toggle will cause the task functionality for the current node to be enabled or disabled. If a node is enabled as a task, the canvas will display a small circle to the left of the node text which can be clicked on using the mouse to indicate that the task has been completed or not. Hovering the mouse over a task circle will display the task completion percent for the given node.

#### Fold

The _Fold_ toggle will cause all of the descendant nodes of the current node to be shown or hidden from view. If nodes are hidden from view, a small rectangle with two dots will be displayed to the right of the node to indicate that nodes are folded. To unfold a node within the canvas, simply click on the fold rectangle using the mouse to bring those nodes back into view.

#### Link Color

The _Link Color_ button displays the current color associated with the node and its parent-attached link. To change this color, click on the button. This will display a color chooser window. Simply select a color from this window and click the **Select** button to change the color.

#### Note

The _Note_ text field allows the user to attach additional textual information to the node. If this field contains text, a special icon will be displayed to the right of the node text in the canvas. If this field is empty, the node icon in the canvas will be removed. You can display the note associated with the node as a tooltip by hovering the mouse pointer over a note icon. You can insert any of the system emoji in this text field by using Control-. (period) and selecting any of the available emoji in the window.

#### Image

The _Image_ area will either display a button to click on to add an image to the current node (if one doesn't currently exist) or it will display the current image as a thumbnail. To add an image, simply click on the **Add Image...** button which will display a standard file chooser. Choosing a file and clicking on the "Select" button will display the image in the sidebar and add an image to the node within the canvas. If the mouse cursor is hovering over the image thumbnail, two buttons will be overlayed on the image. The left button that looks like a pencil, if clicked, will allow the image to be edited in the image editor. The right button that looks like a trash can, if clicked, will remove the image from the current node, updating the canvas as well. To associate a different image with a node, you can either remove it using the trash can icon, click on the edit button and change the image within the image editor, or you can drag and drop an image onto the current image to change it.

#### Button Bar

At the bottom of the panel are four buttons that allow you to quickly operate on the current node.

##### Copy Node

Copies the current node and its descendants for the purposes of pasting it onto another node.

##### Cut Node

Copies the current node and its descendants for the purposes of pasting it onto another node and then removes the current node and its descendants from the canvas.

##### Detach Node

Removes the link from the current node to its parent node, making the current node a root node of a new tree.

##### Delete Node

Removes the current node and its descendants from the canvas.