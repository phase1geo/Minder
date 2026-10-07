---
layout: default
title: Header Bar
parent: User Interface
nav_order: 1
---

# Header Bar
The header bar runs across the top of the main window. It provides quick access to several functions. Simply click on one of the buttons in the header bar to access its functionality.

The following is a representation of the header bar:

![Header Bar](images/header-bar.png)

***

### Document Buttons

The first three buttons in the header bar allow you manage Minder documents in the application and in the file system.

#### New Document

The new document button, when clicked, will clear the current Minder document and start a brand new unnamed document with a single root node created but in the editable state. If the current document is unnamed prior to clicking on this button, Minder will display a file save dialog to allow you to save the document to a named location in the file system.

This function can also be accessed with the keyboard shortcut **Control-N**.

#### Open Document

When this button is clicked, an open file dialog will be displayed, allowing you to select an existing Minder document in the local file system. If a file is chosen, the current document will be cleared and the new Minder document will be displayed in the canvas. If the current document is unnamed prior to clicking this button, Minder will display a save file dialog, allowing the user to save the unnamed document prior to opening the new document.

This function can also be accessed with the keyboard shortcut **Control-O**.

#### Save Document As

Clicking this button will display a file save dialog. Selecting or creating a new document name in the dialog will save the mind map to the named document and will cause the current document to be named. This is not a Save button as the Minder document is updated whenever a change is made within the application that affects the current document.

The function can also be accessed with the keyboard shortcut **Control-Shift-S**.

***

### Undo Buttons

The next two buttons in the header bar allow the user to undo and redo changes made to the mind map. Every change made to the document can be undone using these buttons.

#### Undo Change

The undo button will revert the last change made to the document. Minder supports an unlimited number of undo operations. You can hover the mouse over the icon to display what type of change will be undone if the button is clicked.

This function can also be accessed with the keyboard shortcut **Control-Z**.

#### Redo Change

The redo button will reapply the last change that was undone. You can hover the mouse cursor over the icon to display what type of change will be redone if the button is clicked.

This function can also be accessed with the keyboard shortcut **Control-Shift-Z**.

***

### Document Name

In the middle of the header bar, the name of the current document will be displayed. If the document is unnamed, the name will read "Unnamed Document". To change the document from an unnamed document to a named document, use the **Save Document As** button in the header bar.

***

### Tool Buttons

The remaining buttons on the right side of the header bar contain most of the tools and other features of Minder that are accessible from the header bar.

#### Brainstorm

Clicking this button will reveal the brainstorming UI which will allow you to quickly add ideas to your mindmap document without requiring the user to determine where those ideas fit into the map itself. After ideas have been added, those ideas remain with the mind map document until the user either moves those ideas into the mind map or deletes them.  More information on brainstorming can be found [here](Brainstorming.md)

#### Focus Mode

Clicking on the focus mode toggle with allow you to focus on the currently selected node and its tree path while drawing the rest of the mind map dimly.  You can traverse the tree as normal and Minder will automatically adjust the view to keep you focused on the current node.  Click the focus mode toggle again to return to normal mode.

#### Zoom

Clicking on this button will display a menu of options that will control the amount of zoom that is used within the canvas. More information on zoom support can be found [here](Zoom.md).

#### Search

Clicking on this button will display the document search and search filter popup. More information on search support can be found [here](Search.md).

#### Export

Clicking on this button will display a menu that will provide a series of exporting options. More information on export support can be found [here](Exporting.md).

### Miscellaneous

Clicking on this button will display the miscellaneous menu which contains menu items to view [keyboard shortcuts](Keyboard-shortcuts.md), preferences, and the About menu.

#### Show/Hide Sidebar

Clicking on this button will toggle the display of the sidebar. More information on the sidebar can be found [here](Sidebar.md). 
