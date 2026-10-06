---
layout: default
title: Style Tab
parent: Sidebar
nav_order: 2
has_children: true
---

To view or change the style of nodes, connections and groups (either the currently selected items or all items if nothing is selected), click on the **Style** tab within the sidebar. This will display a list of style selectors which are grouped by the  canvas item that they control.  Each group may have its contents hidden or revealed by clicking on the chevron next to the group name.  Additionally, the style sidebar will dynamically adjust its contents based on the currently selected item(s) in the canvas.

Changing style settings when items are selected will only impact the selected items, leaving all other items in the canvas with their current style intact. To change the settings of all items in the canvas, make sure that no items in the canvas are selected, and make the appropriate changes. Whenever a style setting is changed, the canvas will immediately reflect the style setting, allowing you to adjust the canvas and see its impact in realtime.

### Style Groups

Let's take a closer look at the style settings for each of the following groups:

- [Branch Options](Branch-Options-Group.md)
- [Link Options](Link-Options-Group.md)
- [Node Options](Node-Options-Group.md)
- [Connection Options](Connection-Options-Group.md)
- [Callout Options](Callout-Options-Group.md)

## Style Templates

Being able to change the style of a node, connection or callout is great; however, recreating styles in the sidebar can be cumbersome and can take you out ideation mode quickly. As a result, Minder provides the ability to setup, save and apply style settings with a given name. So if there is a set of style settings that you use to indicate that something is important, you can create those settings using the sidebar and then save those settings with the name of "Important" (or whatever you want to call it). Then, at any point you need to apply that template style to one or more mindmap elements, simply select the them in the mindmap and select the style template to apply and you are done!

### Creating a Style Template

To create a style template, you can either choose the type of mindmap element to style (node, connection or callout) or make sure that nothing is selected to create a global template style.  If you select a mindmap element that is already styled the way that you want, simply click on the `...` button at the top-right corner of the style sidebar panel to display a dropdown menu and select the `Save Style As Template` menu option. This will display a dialog that will allow you to input the name of the template to create. 

Keep in mind that template names will need to be unique for a given element type (node style names must be unique) but can be the same for different element types (example, you have a style that applies to nodes called "Important" while you have a style that applied to connections also called "important").

### Applying a Style Template

After you have created a style template, you can apply that template to the mindmap elements for which it was created by select one or more of those elements in the mindmap, clicking on the `...` button in the style sidebar, clicking the `Load Saved Style` menu option and selecting a named style template from the corresponding list.

### Deleting a Style Template

If you no longer wish to keep a style template around, you can remove that named template by selecting a mindmap element that corresponds to the template, clicking on the `...` button in the style sidebar panel, selecting the `Delete Saved Style` menu option and selecting the style to remove. Once removed, it will no longer appear in the `Load Saved Style` list, but any mindmap elements styled by this template will retain its style information.

Style templates are saved in a file within your local filesystem (typically ~/.local/share/mindmap/templates.xml). As such, template information doesn't get saved into your .mindmap file. Style templates can be created and used by any user mindmap on the local filesystem.
