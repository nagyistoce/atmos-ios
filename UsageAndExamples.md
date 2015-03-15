# Initialization #
After following the InstallationInstructions, you can start adding the connector to your code.  The first step is to simply import <AtmosStore.h> to your code.

After importing the header, you can initialize an AtmosCredentials object.  You will need to pass in your UID, shared secret, hostname, port, and protocol (http or https).  Once you have an Atmos Credentials, you can create the AtmosStore object.

```
    AtmosCredentials *creds = [[AtmosCredentials alloc] init];
    
    creds.tokenId=@"jason";
    creds.sharedSecret=@"1/HpFFAEcbXGXnOaX4Ob3zyYXE8=";
    creds.accessPoint=@"192.168.246.152";
    creds.httpProtocol=@"http";
    creds.portNumber=80;
    
    atmosStore = [[AtmosStore alloc] init];
    atmosStore.atmosCredentials = creds;
```

# Creating an Object #
You can create an object using the createObject:withCallback:withLabel method in AtmosStore.  First, you create an AtmosObject to contain all of your object information.  The object's content can come from either an NSData object or a file path.  Use the dataMode property to set either kDataModeFile for a file path or kDataModeBytes to use bytes.  When using a file path, set the filepath property to your file's pathname.  When using byte mode, set the data property to your NSData object.

For example:
```
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
```

### Blocks ###
Since iOS implements HTTP operations asynchronously, we use Objective-C blocks for callbacks after the operations complete.  When using XCode4, if you simply tab through the method parameters and press the Return key on the block, the appropriate block signature will be automatically generated.  If you're familiar with other languages, blocks are similar to function closures in Javascript.  You can read more about iOS blocks here:
http://developer.apple.com/library/ios/#featuredarticles/Short_Practical_Guide_Blocks/_index.html%23//apple_ref/doc/uid/TP40009758

The easiest method of using blocks is to simply insert the block body in the function call, like this:

```
    [atmosStore createObject:obj 
            withCallback:^BOOL(UploadProgress *progress) {
                
                if(progress.isComplete) {
                    if(progress.wasSuccessful) {
                        // Handle success
                    } else {
                        // Handle failure
                    }
                }
                return YES;
            } 
               withLabel:@"testCreateEmptyObject"];

```

Note that the createObject and readObject callbacks return BOOL.  You should return YES to continue uploading or downloading.  If you want to cancel the operation, return NO.  Also note that create and read may be called multiple times to provide status updates for longer transfers and you should check isComplete to determine whether the operation has completed.  Operations that only invoke the callback once will not have the isComplete property in the callback argument.