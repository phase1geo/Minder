---
layout: default
title: Adding URL Links
parent: Creating a Mind Map
nav_order: 4
---

# Adding a URL link

Minder supports two methods for turning node title text into clickable URL links:

1. Automatically detected embedded links
2. Transform text into a clickable link

If a valid HTTP or mailto URL is entered into a node title, Minder will automatically parse the node text on exiting edit mode and highlight the URL text as a clickable link.

To turn any other text into a clickable link, simply highlight the text when in node title edit mode, right-click to display the contextual menu and select the **Add link** option.  This will display a pop up window that will allow you to enter the URL to associated with the text.  Click the **Apply** button to confirm the URL or click the **Cancel** button to exit the operation.  Once the **Apply** button is clicked, the text will be displayed in the node title as a clickable URL.

Note that a valid URL in Minder must start with any of the following values:

- http://
- https://
- mailto:

The characters following the prefix string must be valid for that URI type and must also not contain any white space characters.

### Jumping to a link

To click on a URL to jump to it in edit mode, position the cursor anywhere within the linked text, right-click to display the contextual menu and select the **Open URL** menu item.  This will automatically open the URL in the preferred application.

To click on a URL when the node title is not being edited, simply hold the Control button while clicking anywhere in the link text.  This will display a popover displaying the URL that will be visited.  To visit the URL, click on the popover URL.  To remove the popover, click anywhere else on the canvas.
