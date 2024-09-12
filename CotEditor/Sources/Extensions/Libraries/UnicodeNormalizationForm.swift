//
//  UnicodeNormalizationForm.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

import UnicodeNormalization

extension UnicodeNormalizationForm {
    
    /// The localized name.
    var localizedName: String {
        
        switch self {
            case .nfd:
                String(localized: "UnicodeNormalization.nfd.label",
                       defaultValue: "NFD",
                       table: "UnicodeNormalization")
            case .nfc:
                String(localized: "UnicodeNormalization.nfc.label",
                       defaultValue: "NFC",
                       table: "UnicodeNormalization")
            case .nfkd:
                String(localized: "UnicodeNormalization.nfkd.label",
                       defaultValue: "NFKD",
                       table: "UnicodeNormalization")
            case .nfkc:
                String(localized: "UnicodeNormalization.nfkc.label",
                       defaultValue: "NFKC",
                       table: "UnicodeNormalization")
            case .nfkcCasefold:
                String(localized: "UnicodeNormalization.nfkcCasefold.label",
                       defaultValue: "NFKC Casefold",
                       table: "UnicodeNormalization")
            case .modifiedNFD:
                String(localized: "UnicodeNormalization.modifiedNFD.label",
                       defaultValue: "Modified NFD",
                       table: "UnicodeNormalization")
            case .modifiedNFC:
                String(localized: "UnicodeNormalization.modifiedNFC.label",
                       defaultValue: "Modified NFC",
                       table: "UnicodeNormalization")
        }
    }
    
    
    /// The localized description.
    var localizedDescription: String {
        
        switch self {
            case .nfd:
                String(localized: "UnicodeNormalization.nfd.description",
                       defaultValue: "Canonical Decomposition",
                       table: "UnicodeNormalization",
                       comment: "description for NFD")
            case .nfc:
                String(localized: "UnicodeNormalization.nfc.description",
                       defaultValue: "Canonical Decomposition, followed by Canonical Composition",
                       table: "UnicodeNormalization",
                       comment: "description for NFC")
            case .nfkd:
                String(localized: "UnicodeNormalization.nfkd.description",
                       defaultValue: "Compatibility Decomposition",
                       table: "UnicodeNormalization",
                       comment: "description for NFKD")
            case .nfkc:
                String(localized: "UnicodeNormalization.nfkc.description",
                       defaultValue: "Compatibility Decomposition, followed by Canonical Composition",
                       table: "UnicodeNormalization",
                       comment: "description for NFKC")
            case .nfkcCasefold:
                String(localized: "UnicodeNormalization.nfkcCasefold.description",
                       defaultValue: "Applying NFKC, case folding, and removal of default-ignorable code points",
                       table: "UnicodeNormalization",
                       comment: "description for NFKD Casefold")
            case .modifiedNFD:
                String(localized: "UnicodeNormalization.modifiedNFD.description",
                       defaultValue: "Unofficial NFD-based normalization form used in HFS+",
                       table: "UnicodeNormalization",
                       comment: "description for Modified NFD")
            case .modifiedNFC:
                String(localized: "UnicodeNormalization.modifiedNFC.description",
                       defaultValue: "Unofficial NFC-based normalization form corresponding to Modified NFD",
                       table: "UnicodeNormalization",
                       comment: "description for Modified NFC")
        }
    }
    
    
    /// Unique identifier for menu item.
    var tag: Int {
        
        Self.allCases.firstIndex(of: self)!
    }
}
