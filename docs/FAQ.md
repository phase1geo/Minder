---
layout: default
title: Frequently Asked Questions
parent: Home
nav_order: 2
---

# Frequently Asked Questions

***

**Q**. I would like to store .minder files in Git, but I run into merge issues with the filetype.  How should I handle this?

**A**. Create a `.gitattributes` file in the root repository directory and add the following contents to it:
   `*.minder -diff merge=binary`
   This will treat .minder files as binary files, replacing the previous version with the new version when Git commits take place.

***

**Q**. I am seeing Minder-Markdown show up in other Gtk applications like Gedit.  How can I get rid of that syntax file?

**A**. Minder 1.15.3 and later versions have changed where the Minder Markdown syntax files are loaded from which is specific to Minder and no longer interferes with other Gtk applications.  If you are using version 1.15.3 or later, you can safely remove these files by deleting the following files:
- `/usr/local/share/gtksourceview-4/language-specs/com.github.phase1geo.minder-markdown.lang`
- `/usr/local/share/gtksourceview-4/styles/com.github.phase1geo.minder.xml`

***

**Q**. After upgrading to Minder 2.0 and starting the application, I am seeing a new popup that is asking me what I want to do with my existing mindmaps.  What is going on here?

**A**. Minder 2.0 changes the saved format of the .minder files.  Prior to Minder 2.0, .minder files were a simple XML file that represented the state of the mind map, but it was not robust enough to store other data used in the mind map such as images.  The Minder 2.0 .minder format changes this.  It is still a single file, but it is a zipped file which contains all the necessary files to represent a mind map.  It also is robust enough to provide new features in the future.

Since the .minder files are different formats, these files either need to be upgraded to the new format (which Minder can do for you) or they can be opened in "read only" mode since Minder no longer supports modifying/saving to the older formats.  It should be noted that files opened in "read only" mode can always be saved into the new version by clicking on the **Save As** button in the application header bar.  In addition to opening in read-only mode, Minder can upgrade the files using the same name as the older version.  It can also, optionally, rename the older version prior to upgrading the file.

***
