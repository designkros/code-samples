<h1>Code Samples</h1>

<h2>Connect Device Carousel</h2>
Carousel created using UICollectionView. Displays each available device within range as a UICollectionViewCell (plus an additional cell for "Searching" animation). Supports custom gestures to swipe left/right to select device, along with drag down to connect to that device.

<h2>Custom Navigation Controller</h2>
Custom navigation controller was created to seamlessly transition between Create Account and Login. Transition between screens are also much more fluid than the build in "push" transitions. This class was created because so many of the view controllers shared the same assets/layout and we didn't want them to be pushed over and over and appear duplicated. With this custom navigation controller have the appearance of the assets being shared (static) across all the screens and much more subtle transitions.

[Watch example on Youtube](https://youtu.be/t0mZ-sKAoDo)

<h2>Custom Wheel Control</h2>
Custom user interface built with UICollectionView and custom UICollectionViewFlowLayout subclass. All gesture code built from scratch including animation easing.

[Watch example on Youtube](https://youtu.be/4i-Ha0BH1kI)

<h2>Device Communication</h2>
Device communication library. Scans and connects to nearby devices over BLE. Parses bit data into three data structures. The "header" is parsed first to reveal info on incoming patient data. Then two sections of patient data is transmitted.

<h2>Internal Notification Manager</h2>
Shows a custom notification bar at the top of the screen while the user is in the app. The notification bar is shown in it's own window so it appears above any view controller in the app — no matter what screen you're currently on. This allows all of the code to be centralized.

There are two types of notifications this app is interested in. The first are external notifications fired by UserNotification (local). When the app is open iOS does not show it's default notification bar, so a custom user interface must present it. The LocalNotificationManager listens for these incoming messages from UserNotification and parses them into a InternalNotificationView that gets passed to the InternalNotificationManager for presentation. The second are Bluetooth device notifications. The PairedDeviceManager listens for incoming messages from the paired device and parses them into InternalNotificationView or InternalSyncNotificationView instances and passes them to the InternalNotificationManager for presentation.

The InternalNotificationManager is smart enough to accept any amount of views at once and queues them for display at 3 second intervales. It also supports a priority to move some notifications (syncing) to the front of the queue for quicker display.

[Watch example on Youtube](https://youtu.be/Yg9xiA8lNec)

<h2>Simple App Instructions</h2>
Simple intro/instruction carousel built using UIScrollView and very concise code. Finishes touches include cross-fades and dynamically resizing UILabel on line height changes.

[Watch example on Youtube](https://youtu.be/Vy85EDq8q_E)

<h2>Vision Test</h2>
"Visual Acuity" for the iPad. Scientifically calibrated to be administered at 3 meters with an iPad Pro. Supports an external Bluetooth keyboard for the administrator to enter the participants vocal response.

Advanced use of UICollectionView to advanced through the eye chart. Complex StaticVisionEngine (algorithm) for selecting the next size letter for display and when to end the test.