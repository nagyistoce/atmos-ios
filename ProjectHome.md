EMC Atmos cloud storage connector for Apple iOS 6.0 and higher.

## Installation ##
See the InstallationInstructions page for instructions on how to integrate the connector with your XCode 4 project.

## Usage ##
See the UsageAndExamples page for a quick tutorial on how to use the connector.  There also are testcases checked in to SVN you can use for reference.

# Current Version: 2.1.2 #
  * Fixes HTTP Date header generation for non-US locales.  RFC822 states that dates must be formatted in the en\_US locale.
  * Added support for shareable URLs.

# Previous Version: 2.1.1 #
  * Added some missing files to archive

# Older Version: 2.1.0 #
  * Upgraded project to iOS 6
  * Upgraded version of GHUnit framework for unit tests under iOS 6
  * Added support for Atmos 2.1.0 keypools
  * Added support for Atmos 2.1.0 anonymous access tokens
  * Lots of bugfixes

# Older Version: 0.9.0 #
  * Most functionality is now implemented with the exception of Versioning
  * New feature for Atmos 1.4.1 only:
    * listDirectory supports metadata (listDirectoryWithAllMetadata). This will drastically improve performance when you need directory contents _and_ information about the objects (user and system metadata).
  * Lots of bugfixes, including
    * Unicode filename handling
    * Large object support (>2GB)
    * Fixed isEqual support in AtmosObject


# Older Version: 0.6.0 #
  * Added license to source files
  * Standardized callback blocks and response objects
  * Cleaned up memory management; fixed some leaks
  * Added more testcases

# Older Version: 0.5.0 #
  * Refactoring to use iOS 4.0 blocks
  * Added test cases