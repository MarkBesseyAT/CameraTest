# CameraTest - a basic demo of a CoreMediaIO camera extension

## What is it?
This project is a simple example of building a CoreMediaIO camera extension, and an application that communicates with it.

## Project components
### CameraTest - the application target
### CameraExtension - the camera extension

## Development
To get started with the project, you'll first need to change the Bundle Identifier and Team settings for both targets, to match your own Team in the Apple Developer Portal. You'll also want to check the App Groups for both targets. I don't know if those are actually used for anything, but the default Camera Extension target includes an App Groups setting, so it might be important. 

## Known issues
### A reboot is required to replace the currently-installed extension
This is presumably a bug in CoreMediaIO extensions, but when a request is made to install the extension, via OSSystemExtensionRequest.activationRequest, it always "succeeds" but the new extension doesn't actually start running until a system reboot happen.

