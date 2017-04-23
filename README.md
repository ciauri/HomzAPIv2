# HomzAPIv2
A proper RESTful API written in Swift using the Perfect framework

## Building


### Ubuntu 16.04

1. Install Swift 3.1 dependencies

`sudo apt-get install clang libicu-dev`


2. Get the latest Swift 3.1 snapshot

`wget https://swift.org/builds/swift-3.1-release/ubuntu1604/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu16.04.tar.gz`

3. Import swift GPG keys

`wget -q -O - https://swift.org/keys/all-keys.asc |   gpg --import -`

4. Unzip the Swift bundle you downloaded above and add the contained `/usr/bin` folder do your PATH

```
tar xzf swift-3.1-RELEASE-ubuntu16.04.tar.gz
export PATH=/absolute/path/to/swift-3.1-RELEASE-ubuntu16.04/usr/bin:"${PATH}"
```

5. Install NewHomzAPI dependencies

`sudo apt-get install libpython2.7 libcurl3 libmysqlclient-dev libssl-dev uuid-dev`

6. Clone the repo and build

```
git clone https://github.com/ciauri/HomzAPIv2.git
cd HomzAPIv2
swift build
```

7. The binary will be built and reside in the .build/debug folder and be named `NewHomzAPI`




### macOS

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
3. `./NewHomzAPI -config /path/to/your/plist`
4. That's it!

- If you're using Xcode for development, make sure you Edit Scheme -> Arguments -> add the `-config /path/to/config.plist` as a command line argument

## Test Deployment
You can hit up the [sample environment](http://api.newhomz.com:8181/v1/listings/featured) if you want to see this puppy in action with a live database
