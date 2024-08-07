//
//  NSValidatedUserInterfaceItem.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit

public extension NSValidatedUserInterfaceItem {
    
    /// The tooltip to display when someone hovers over the item.
    @MainActor var toolTip: String? {
        
        get {
            switch self {
                case let item as NSMenuItem:
                    item.toolTip
                case let item as NSToolbarItem:
                    item.toolTip
                case let item as NSCustomTouchBarItem:
                    item.view.toolTip
                default:
                    // -> Only NSMenuItem and NSToolbarItem inherit NSValidatedUserInterfaceItem.
                    preconditionFailure()
            }
        }
        
        set {
            switch self {
                case let item as NSMenuItem:
                    item.toolTip = newValue
                case let item as NSToolbarItem:
                    item.toolTip = newValue
                case let item as NSCustomTouchBarItem:
                    item.view.toolTip = newValue
                default:
                    preconditionFailure()
            }
        }
    }
}
