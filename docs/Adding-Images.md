---
layout: default
title: Images
parent: Creating a Mind Map
nav_order: 2
---

# Images

Minder supports adding user images to mind-maps as a part of a node in the tree.

### Special Note About Image Handling in Minder

Images are handled in a special way with Minder that is worth noting here.

When an image is added to a mind-map (either from a file, from the clipboard, or via a drag-and-drop operation), Minder creates a copy of this image and stores the raw image it in the user's data directory (this is typically ~/.local/share/minder/images in systems like elementary OS).  The image is given a unique ID which is stored in the .minder file when changes are made to the mind map.  It is important to note that as of Minder version 1.12.0, images are not automatically saved in the .minder XML file to improve save performance.  If the user wants to share the Minder mind map with another user not on the local machine, a Portable Minder file needs to be exported from within the [Exporting](Exporting.md) UI.  This file format is an archived format which stores the .minder information along with all associated assets (i.e., images used within the mind map).

Once the .pminder file has been created, it can be opened by Minder as you would with any other importable file type.  In this case, when a .pminder file is created, the stored images will be copied into the user's data directory where it will be used as normal.

### Adding an Image

Adding images can be done in several ways:

- Right-click on a selected node to display the contextual menu and select the **Add Image** option.  This will display an open file dialog where you can select an existing image file anywhere on your filesystem.
- Drag and drop an image from your file browser or from a web browser onto an existing node.
- Copy an image to the clipboard, select a node in the mind-map and select Paste option (Control-V).
- Select a node, go to the Node Inspector sidebar panel, and click the "Add Image..." button at the bottom of the panel.  This will display an open file dialog to select an image to add to the node.

### Changing an Image

Once a node has been associated with an image, you can change the image to a different image in the following ways:

- Double-click on the image to display the image editor popup, select the **Change Image**, and choose a new image from the open file dialog.  Click **Apply**.
- Double-click on the image to display the image editor popup, and drag-and-drop an new image into the image in the editor.  Click **Apply**.
- Drag and drop an image on the node.
- Copy and image to the clipboard and paste it into the node.
- Select a node, go to the Node Inspector sidebar panel and click on the edit button just above the image in the sidebar to display the image editor.  Modify the image as described above.

### Removing an Image

There are several ways to remove the image from a node:

- Right-click on a node to display the contextual menu and select the "Remove Image" option.
- Select a node, put the Node Inspector sidebar panel into view, and click on the trash icon just above the image.
- Double-click an image to display the image editor, select the trash icon, and click on the **Apply** button.

### Resizing an Image

To resize an image within a node, click and drag the resize area at the top of the node to the left/right to make the image larger or smaller.  The image will always maintain its proportions.

### Cropping an Image

To crop an image, double-click the image to show the image editor.  Then click and drag any of the crop handles to adjust the cropping.  Finally, click the Apply button to commit the cropping to the node image.
