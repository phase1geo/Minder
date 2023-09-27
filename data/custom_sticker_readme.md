This directory exists to allow the user to add and manage any custom stickers that can be used by Minder.

If this directory contains any subdirectories which have image files in them, each image file will be loaded
into Minder at application start as a custom sticker.  The name of the subdirectory containing the image file
ill be be used as the sticker category.  You can either use the existing subdirectories (which correspond to
built-in sticker categories) or you may add new directories as you desire.

## Categories

Each subdirectory within this directory will create a sticker category within Minder.  The name of the
category subdirectory can be any legal directory name though it should be as short as possible in character
count (to avoid UI issues in displaying the category).  Minder will perform the following transformations
to the category subdirectory name to help it conform to the built-in category names:

1.  All characters will be converted to lowercase.
2.  The first character of each word will be uppercase.
3.  The word "And" will be converted to lowercase.
4.  All underscores will be converted to space characters.

## Sticker Image Files

Within the category subdirectory will be placed image files.  Minder supports many types of image file formats
which include JPEG, PNG and SVG.  SVG images are preferred as they won't have scaling artifacts if the sticker is
scaled up.  If the image file is not an SVG, it is recommended that the image width and height not be less than
256 pixels in both directions.  It is also highly recommended that the sticker be a square image (or nearly square).

The file extensions on each image file should match their data file type.

The name of the image file (minus the file extension) will be used as the sticker tooltip which is displayed
when the cursor is hovered over the sticker image.  The name of the image file will be modified as follows to produce
the tooltip.

1.  The first character will be converted to uppercase.
2.  Any underscore characters will be converted to space characters.

You may have as many image files in a category subdirectory as needed.  Keep in mind that if the image files are large
in file size and there are a large enough number, it may have an impact on application startup time.

## Final Note

Once you have made changes to any files or directories in this directory, you will need to close the current Minder
application (if running) and restart it to see the sticker updates within the application.
