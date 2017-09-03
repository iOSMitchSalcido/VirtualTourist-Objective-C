# VirtualTourist-Objective-C
Rewrite of VirtualTourist using Objective-C
170902
VirtualTourist-Obj App Info:

An app that allows the user to retrieve photos from around the world and preview them in a photo album. Locations are
selected from a map, and photos from that location are then downloaded from Flickr.

Created as an exercise to familiarize myself with Objective-C. This app was originally written in Swift as the final project in
Udacity iOS class "Data Persistence with Core Data". This is a re-write of the app using Objective-C

The app provides two main views and a "help" view. The mapView allows the user to drop pins on locations. Once a pin is dropped,
photos, or "flicks" are downloaded using the Flickr API that are tagged to the coordinates that the pin was dropped.
The pin/flicks are persisted using Core Data.

An accessory view is presented when a pin is tapped. This view contains two buttons: Delete and Album. Pressing delete
will delete the pin from the map (and also delete the flicks for that pin). Pressing album will invoke the AlbumVC (push),
and present the flicks for that pin in a collectionView.

The AlbumVC along with it's collectionView, allow the user to preview each flick (single tap a flick) and also edit the
flicks (delete). In addition, the user can reload a new set of flicks (deleting the previous set of flicks).
