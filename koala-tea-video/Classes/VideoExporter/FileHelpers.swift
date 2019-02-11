//
//  FileHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import Foundation

public class FileHelpers {
    public class func getDocumentsURL(for filename: String, extension extensionString: String) -> URL? {
        guard let docsDirectory = getDocumentsDirectory() else { return nil }
        let url = docsDirectory.appendingPathComponent(filename + "." + extensionString)
        return url
    }

    private class func getDocumentsDirectory() -> URL?  {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    public static func removeFileAtURL(fileURL: URL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
            print("FileManager: Can not find file to remove")
        }
    }
}
