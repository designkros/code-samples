<h1>Code Samples</h1>

<h2>Connect Device Carousel</h2>
Praesent id velit ut velit tristique pellentesque nec sit amet ipsum. Curabitur orci diam, venenatis sed scelerisque at, cursus id neque. Sed tristique ornare convallis. Sed tempor mauris eget magna lacinia tristique. Interdum et malesuada fames ac ante ipsum primis in faucibus. Curabitur sit amet cursus eros. Phasellus tincidunt luctus justo, a feugiat libero accumsan vel. Donec eget auctor purus.

<h2>Custom Navigation Controller</h2>
//

[Watch example on Youtube](https://youtu.be/t0mZ-sKAoDo)


<h2>Custom Wheel Control</h2>
Custom user interface built with UICollectionView and custom UICollectionViewFlowLayout subclass. All gesture code built from scratch including animation easing.

[Watch example on Youtube](https://youtu.be/4i-Ha0BH1kI)

<h2>Device Communication</h2>
Device communication library. Scans and connects to nearby devices over BLE. Parses bit data into three data structures. The "header" is parsed first to reveal info on incoming patient data. Then two sections of patient data is transmitted.

<h2>Internal Notification Manager</h2>
Shows a custom notification bar at the top of the screen while the user is in the app. There are two types of notifications this app is interested in. The first are external notifications fired by UserNotification (local). When the app is open iOS does not show it's default notification bar, so a custom user interface must present it. The LocalNotificationManager listens for these incoming messages from UserNotification and parses them into a InternalNotificationView that gets passed to the InternalNotificationManager for presentation. The second are Bluetooth device notifications. The PairedDeviceManager listens for incoming messages from the paired device and parses them into InternalNotificationView or InternalSyncNotificationView instances and passes them to the InternalNotificationManager for presentation.

The InternalNotificationManager is smart enough to accept any amount of views at once and queues them for display at 3 second intervales. It also supports a priority to move some notifications (syncing) to the front of the queue for quicker display.

[Watch example on Youtube](https://youtu.be/4i-Ha0BH1kI)

<h2>Simple App Instructions</h2>
Simple intro/instruction carousel built using UIScrollView and very concise code. Finishes touches include cross-fades and dynamically resizing UILabel on line height changes.

[Watch example on Youtube](https://youtu.be/Vy85EDq8q_E)

<h2>Vision Test</h2>
Praesent id velit ut velit tristique pellentesque nec sit amet ipsum. Curabitur orci diam, venenatis sed scelerisque at, cursus id neque. Sed tristique ornare convallis. Sed tempor mauris eget magna lacinia tristique. Interdum et malesuada fames ac ante ipsum primis in faucibus. Curabitur sit amet cursus eros. Phasellus tincidunt luctus justo, a feugiat libero accumsan vel. Donec eget auctor purus.