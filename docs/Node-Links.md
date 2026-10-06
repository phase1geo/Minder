---
layout: default
title: Adding Node Links
parent: Creating a Mind Map
nav_order: 7
---

# Node Links

In addition to creating connections between nodes, which are visible lines connecting nodes, Minder allows you to create a link to another node in either the same mind-map or a node in a different mind-map altogether.  Creating these links can be useful when presenting or for creating "deep mind-maps".

Once a node link is added to a node, you can traverse to the linked node by clicking on the arrow displayed on the right side of the node.

Let's go over how to add them to a node and remove them from a node.

### Create a node link to another node in the same map

To create a node link to a node in the same mind-map, first select the node that will contain the node link.  Then hit the **'y'** key.  This will create a link connection that will follow the mouse cursor.  Drag the mouse to the node to link to (or use the arrow keys to traverse the mind-map) and hit the enter to key to create the node link.  The node containing the link will display a filled-in arrow on the right side of the node.  Clicking this arrow will adjust the mind map to display the linked to node and select it.

### Create a node link to a node in another map

To create a node link to a node in a mind map in a different file, open that mind map in a new tab, select the node to link to, and copy that node (**Control-c**).  After that, go to the mind map containing the node to contain the node link, select that node, and hit **Control-y**.  The node containing the link will display a hollow arrow on the right side of the node.  Clicking this arrow will open the mind map containing the linked node (if it isn't already opened within the application), select the tab containing that map, place the linked to node within view and select that node.

### Removing a node link

To remove an existing node link from a node, simply select that node and hit the **'y'** key.  This will remove the linked node arrow regardless of whether the linked node is containined in the same or different map.

### Adding Node Links to Notes

If you would like to link a node to more than one node in either the same mind map or a different one, this can be accomplished using the node note area. Simply copy the node to link to using **Control-c** and then paste into the node's note that will contain the link. The resulting text that will be pasted will look like a Markdown link. To select a linked node using the notes field, simply 'Control+mouse click' on the underlined portion of the node link. This will select that node and place it into view within the canvas. If the node exists in a separate mind map, that mind map will be loaded into Minder (if it is not already loaded), the node will be selected and placed into view in that mind map's tab.
