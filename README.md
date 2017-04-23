# HomzAPIv2
A proper RESTful API written in Swift using the Perfect framework

## Building

To install MySQL:

```
brew install mysql
```

Unfortunately, at this point in time you will need to edit the mysqlclient.pc file located here:

```
/usr/local/lib/pkgconfig/mysqlclient.pc
```

Remove the occurrance of "-fno-omit-frame-pointer". This file is read-only by default so you will need to change that first.

`swift build`

If you would like to develop in Xcode:

`swift package generate-xcodeproj`

## Running
1. Modify the `config_sample.plist` to your specifications.
2. Use the command line argument `-config` to point to the desired config plist.
3. `./NewHomzAPI`
4. That's it!

- If you're using Xcode for development, make sure you Edit Scheme -> Arguments -> add the `-config path/to/config.plist` as a command line argument

## Test Deployment
You can hit up the [sample environment](http://api.newhomz.com:8181/v1/listings/featured) if you want to see this puppy in action with a live database
