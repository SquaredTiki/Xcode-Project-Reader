# Xcode Project Reader (`XCDProjectCoordinator`)

This projects reads and displays an Xcode Projects file structure in an `NSOutlineView` without the use of any private frameworks. 

`XCDProjectCoordinator` can be used in one of two ways:

- Firstly you can access the `files` property which is generated when the project is parsed and use that to look at the file structure, however this is best suited for use in outline views and isn't great anywhere else such as in `UINavigationController` when navigating through levels. 
- Secondly you can use a number of convenience methods which will give you all the UUID's of children of a certain group and then get the information about them individually. This way you only have access to the information you want and it is much more direct.

## Features

- Parsing Xcode projects
- Removing items
- Adding groups and files
- Creating a new project (iOS only)
- Convenient list of items/files for use with `NSOutlineView`

## To-do

- Add some decent comments so people know what's what
- Add support for adding frameworks (not just to the file list but also to the build phases)
- *Various other things which I can't think of right now*

## Attribution

If you are using `XCDProjectCoordinator` in your project please make sure you leave credit where credit is due.