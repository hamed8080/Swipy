# Swipy
<br />
<br />

### Do you want Widget-style animation on iOS devices in your app by swiping and changing the view?
<br />

## Installation

#### SPM 

Add in `Package.swift`:

```swift
.package(url: "https://github.com/hamed8080/Swipy", branch: "main")
```

## Usage 
```swift
VSwipy(data, selection: $selectedItem) { item in
    UserConfigView(userConfig: item)
        .frame(height: containerHeight)
        .background(Color.swipyBackground)
        .cornerRadius(12)
} onSwipe: { item in
    // Write your code here after the switching has been completed.
}
.frame(height: containerHeight)
.background(Color.orange.opacity(0.3))
.cornerRadius(12)

VSwipy(users) { user in
    HStack {
        ...
    }
    .frame(minHeight: 0, maxHeight: containerHeight)
    .background(Color.white)
    .cornerRadius(24)

} onSwipe: { item in
    selectedItem = item
}
.frame(minHeight: 0, maxHeight: containerHeight)
.background(Color.black)
.cornerRadius(24)
```
<br/>
<br/>


## Contributing to Swipy

Please see the [contributing guide](/CONTRIBUTING.md) for more information.
