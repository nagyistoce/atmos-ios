The easiest way to add the connector to your code is to extract the project into your XCode 4 workspace.

## Save your project as a workspace ##
If you haven't already, upgrade your project to a workspace by selecting File->Save as Workspace...

## Extract the connector TAR file into your project folder ##
Download the latest version and extract the archive.  Inside you will see an atmos-ios folder and an atmos-ios.xcodeproj file.  Move these two items into your project folder

![http://atmos-ios.googlecode.com/svn/trunk/images/drag_to_project.png](http://atmos-ios.googlecode.com/svn/trunk/images/drag_to_project.png)

## Add the connector to your workspace ##
Inside XCode, right-click and Add Files To...  In the dialog, select the .xcodeproj folder.  You will see a 2nd project appear in your workspace.

![http://atmos-ios.googlecode.com/svn/trunk/images/add_to_workspace.png](http://atmos-ios.googlecode.com/svn/trunk/images/add_to_workspace.png)

## Build the Library ##
Before using, build the library once.  In your scheme list, pick "atmos-ios | iOS Device" and press Command-B to build it.  When done, switch back to your project's scheme.

![http://atmos-ios.googlecode.com/svn/trunk/images/change_scheme.png](http://atmos-ios.googlecode.com/svn/trunk/images/change_scheme.png)

## Add link target ##
Inside the project properties for your project, go to the "Build Phases" tab.  You'll see "Link Binary with Libraries".  Expand the section and press the + button.  You'll see a list of libraries and frameworks.  Under workspace you should see "libatmos.a".  Add this library and click OK.

![http://atmos-ios.googlecode.com/svn/trunk/images/add_library_to_link_targets.png](http://atmos-ios.googlecode.com/svn/trunk/images/add_library_to_link_targets.png)

## Add linker flags ##
There's currently a bug in the iOS compiler that prevents applications from seeing Objective-C Category objects in libraries.  To work around this, add the linker flag -all\_load to Build Settings->Linking->Other Linker Flags.

## Add header search path ##
To find the library's headers, find Build Settings->Search Paths->Header Search Paths and add the value $(BUILT\_PRODUCTS\_DIR)/usr/local/include