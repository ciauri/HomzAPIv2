//
//  Image.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import Foundation
import PerfectLib
import PerfectMySQL

class Image: JSONConvertibleObject {
    enum ImageType {
        case gallery
        case floorplan
    }
    
    static let columns = ["photo", "caption", "showOrder", "cID"]
    
    var url: URL
    var position: Int
    var caption: String = ""
    var listingId: Int
    
    init?(withResult result: [String:String]) {
        guard
            let url = result["photo"]?.urlValue,
            let listingId = result["cID"]?.intValue else {
                return nil
        }
        self.url = url
        self.position = result["showOrder"]?.intValue ?? 0
        self.listingId = listingId
        super.init()
        caption = result["caption"] ?? caption
    }

    
    override func getJSONValues() -> [String : Any] {
        return [
            "url": url.absoluteString,
            "position": position,
            "caption": caption
        ]
    }
}

extension Image {
    
    /// Fetches images that belong to the desired listings identified by their IDs
    ///
    /// - Parameters:
    ///   - listingIDs: An array of IDs of listings you would like images for
    ///   - type: Indicates whether or not you want Floorplans or Gallery images
    ///   - database: The database connection to be used
    ///   - completion: A block returning a dictionary keyed on the listing IDs and valued with an array of found images
    class func findImages(withListingIds listingIDs: [Int], type: ImageType, in database: Database = Database(), completion: @escaping ([Int:[Image]]?)->()){
        // Construct SQL
        let columns = Image.columns.joined(separator: ",")
        let sqlListingIDs = listingIDs.map({ String($0) }).joined(separator: ",")
        let table = type == .gallery ? "gallery" : "floorplans"
        let statement =
            "SELECT \(columns) " +
            "FROM \(table) " +
            "WHERE cID IN (\(sqlListingIDs))"
        database.performQuery(statement: statement, completion: { results in
            guard let results = results else {
                NSLog("Error fetching listings")
                completion(nil)
                return
            }
            var imageDict: [Int:[Image]] = [:]
            for row in results {
                // Parse the image
                let imageResult = Dictionary<String, String>.combining(keyArray: Image.columns, valueArray: row)
                guard let image = Image(withResult: imageResult) else { continue }
                guard imageDict[image.listingId] != nil else {
                    imageDict[image.listingId] = [image]
                    continue
                }
                imageDict[image.listingId]!.append(image)
            }
            completion(imageDict)
        })
    }
    
    class func findImages(forListingId id: Int, type: ImageType, in database: Database = Database(), completion: @escaping ([Image]?)->()){
        // Construct SQL
        let columns = Image.columns.joined(separator: ",")
        let table = type == .gallery ? "gallery" : "floorplans"
        let statement =
            "SELECT \(columns) " +
            "FROM \(table) " +
            "WHERE cID = \(id)"
        database.performQuery(statement: statement, completion: { results in
            guard let results = results else {
                NSLog("Error fetching images")
                completion(nil)
                return
            }
            var images: [Image] = []
            for row in results {
                // Parse the image
                let imageResult = Dictionary<String, String>.combining(keyArray: Image.columns, valueArray: row)
                guard let image = Image(withResult: imageResult) else { continue }
                images.append(image)
            }
            completion(images)
        })
    }
}
