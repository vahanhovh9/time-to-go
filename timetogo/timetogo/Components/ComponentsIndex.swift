//
//  ComponentsIndex.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

/// This file serves as an index for all available components in the component library.
/// See individual component files for detailed documentation.

// MARK: - Components Available

/*
 1. Checkmark - A checkmark component with unchecked and checked states
    Location: Components/Checkmark.swift
    Usage: Checkmark(state: .unchecked) or Checkmark(state: .checked)
 
 2. Dropdown - A dropdown selector component
    Location: Components/Dropdown.swift
    Usage: Dropdown(label: "Label", items: [...], selectedItem: $binding)
 
 3. Button - A custom button with filled and outline styles
    Location: Components/Button.swift
    Usage: CustomButton(title: "Title", style: .filled, action: { })
 
 4. DayPicker - A day selection component with checkmark
    Location: Components/DayPicker.swift
    Usage: DayPicker(day: "Monday", isSelected: $binding)
*/

// MARK: - Design Tokens Used

// Colors:
// - .grey10 (#EBEBEB) - Background
// - .grey30 (#949494) - Border
// - .grey50 (#3E3E3E) - Dark text
// - .black (#000000) - Primary background/text
// - .white (#FFFFFF) - Checkmark background

// Typography:
// - .labelStyle() - Dropdown labels and day names
// - .h4Style() - Button and dropdown text

// Dimensions:
// - Standard component height: 56px
// - Corner radius: 5px
// - Border width: 1px
// - Checkmark size: 24x24px


