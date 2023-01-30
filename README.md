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
VSwipy(users, containerHeight: containerHeight) { user in
    HStack {
        Text("Test")
            .font(.subheadline)
    }
    .frame(minHeight: 0, maxHeight: containerHeight)
    .background(.green.opacity(0.5))
    .cornerRadius(24)
} onSwipe: { item in
    selectedItem = item
}
.frame(minHeight: 0, maxHeight: containerHeight)
.background(.ultraThinMaterial)
.cornerRadius(24)
```
<br/>
<br/>


## Contributing to Swipy

Please see the [contributing guide](/CONTRIBUTING.md) for more information.
