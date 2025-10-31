# Style Guide Reference

## Typography Styles

### Usage in Views

Apply typography styles using view modifiers:

```swift
Text("12:30 PM")
    .timeStyle()
    
Text("Heading")
    .h1Style()
    
Text("Heading")
    .h2Style()
    
Text("Heading")
    .h3Style()
    
Text("Heading")
    .h4Style()
    
Text("Body text content")
    .bodyTextStyle()
    
Text("Label")
    .labelStyle()
    
Text("Small text")
    .bodySmallStyle()
```

### Style Specifications

| Style | Font | Weight | Size | Tracking | Line Height |
|-------|------|--------|------|----------|-------------|
| Time | SF Pro | Bold | 80px | -4p | 100% |
| H1 | SF Pro | Bold | 40px | -2p | 100% |
| H2 | SF Pro | Bold | 24px | -1px | 100% |
| H3 | SF Pro | Bold | 20px | -0.5px | 100% |
| H4 | SF Pro | Bold | 17px | -1px | 120% |
| Body Text | SF Pro | Medium | 20px | -1px | 123% |
| Label | SF Pro | Medium | 16px | -0.5px | 100% |
| Body Small | SF Pro | Medium | 14px | 0px | 120% |

## Color Palette

### Usage

```swift
.foregroundColor(.white)
.foregroundColor(.grey10)
.foregroundColor(.grey30)
.foregroundColor(.grey50)
.foregroundColor(.black)

.background(.white)
.fill(.grey10)
```

### Color Values

| Name | Hex Code |
|------|----------|
| White | #FFFFFF |
| Grey 10 | #EBEBEB |
| Grey 30 | #949494 |
| Grey 50 | #3E3E3E |
| Black | #000000 |

