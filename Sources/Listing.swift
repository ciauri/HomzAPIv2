//
//  Listing.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import Foundation
import PerfectLib
import PerfectHTTPServer
import PerfectMySQL
import Dispatch

class Listing: JSONConvertibleObject {
    static let sparseColumns: [String] = ["id", "listing", "photo", "active", "lat", "lng", "builderID", "priceTxt", "priceLow", "priceHigh", "sqftLow", "sqftHigh", "bedLow", "bedHigh", "bathLow", "bathHigh"]
    static let detailColumns: [String] = ["propType", "city", "county", "state", "zip", "description", "email", "website", "phone", "vid", "schoolDistrictName"]
    static let allColumns: [String] = sparseColumns + detailColumns
    
    private var sparseEntity: Bool = true
    
    // Sparse properties
    var id: Int = -1
    var name: String = "<null>"
    var builderId: Int = -1
    var status: Status = .inactive
    var featuredPhoto: URL?
    var coordinate: NSPoint = NSPoint(x: 0, y: 0)
    var priceText: String = "From the"
    var price: Range<Int> = Range(uncheckedBounds: (0,0))
    var squareFootage: Range<Int> = Range(uncheckedBounds: (0,0))
    var bedrooms: Range<Int> = Range(uncheckedBounds: (0,0))
    var bathrooms: Range<Float> = Range(uncheckedBounds: (0,0))
    
    // Detailed properties
    var builder: Builder?
    var description: String = ""
    var schoolDistrictName: String = ""
    var gallery: [Image] = []
    var floorplans: [Image] = []
    var propertyType: String = ""
    var email: String = ""
    var website: URL?
    var video: URL?
    var phone: String = ""
    var city: String = ""
    var county: String = ""
    var state: String = ""
    var zip: String = ""

    enum Status: Int {
        case inactive
        case active
        case featured
        
        var jsonValue: String {
            switch self {
            case .inactive:
                return "INACTIVE"
            case .active:
                return "ACTIVE"
            case .featured:
                return "FEATURED"
            }
        }
    }

    init(withSparseResult result: [String:String]) {
        super.init()
        id = result["id"]?.intValue ?? id
        builderId = result["builderID"]?.intValue ?? builderId
        name = result["listing"] ?? name
        priceText = result["priceText"] ?? priceText
        featuredPhoto = result["photo"]?.urlValue ?? featuredPhoto

        if
            let lat = result["lat"]?.doubleValue,
            let long = result["lng"]?.doubleValue {
            coordinate = NSPoint(x: CGFloat(lat) , y: CGFloat(long))
        }
        
        if
            let priceLow = result["priceLow"]?.intValue,
            let priceHigh = result["priceHigh"]?.intValue {
            price = Range(uncheckedBounds: (priceLow, priceHigh))
        }
        
        if
            let squareFootLow = result["sqftLow"]?.intValue,
            let squareFootHigh = result["sqftHigh"]?.intValue {
            squareFootage = Range(uncheckedBounds: (squareFootLow, squareFootHigh))
        }
        
        if
            let bedLow = result["bedLow"]?.intValue,
            let bedHigh = result["bedHigh"]?.intValue {
            bedrooms = Range(uncheckedBounds: (bedLow, bedHigh))
        }
        
        if
            let bathLow = result["bathLow"]?.floatValue,
            let bathHigh = result["bathHigh"]?.floatValue {
            bathrooms = Range(uncheckedBounds: (bathLow, bathHigh))
        }
        
        if
            let statusInt = result["active"]?.intValue,
            let status = Status(rawValue: statusInt) {
            self.status = status
        }
    }
    
    
    convenience init(withResult result: [String:String]) {
        self.init(withSparseResult: result)
        sparseEntity = false
        propertyType = result["propType"] ?? propertyType
        description = result["description"] ?? description
        email = result["email"] ?? email
        website = result["website"]?.urlValue ?? website
        phone = result["phone"] ?? phone
        video = result["vid"]?.urlValue ?? video
        schoolDistrictName = result["schoolDistrictName"] ?? schoolDistrictName
        city = result["city"] ?? city
        county = result["county"] ?? county
        state = result["state"] ?? state
        zip = result["zip"] ?? zip
    }
    
    override func getJSONValues() -> [String : Any] {
        var json: [String:Any] = [
            "id": id,
            "href": href ?? "",
            "links": links,
            "name": name,
            "builderID": builderId,
            "coordinate": ["latitude":Double(coordinate.x), "longitude":Double(coordinate.y)],
            "price": ["min":price.lowerBound, "max":price.upperBound],
            "priceText": priceText,
            "squareFootage": ["min":squareFootage.lowerBound, "max":squareFootage.upperBound],
            "bedrooms": ["min":bedrooms.lowerBound, "max":bedrooms.upperBound],
            "bathrooms": ["min":Double(bathrooms.lowerBound), "max":Double(bathrooms.upperBound)],
            "status": status.jsonValue
        ]
        
        if let featuredPhoto = featuredPhoto {
            json["featuredPhoto"] = featuredPhoto
        }

        if !sparseEntity {
            if let builder = builder {
                json["builder"] = builder
            }
            let extendedFields: [String:Any] = [
                "gallery": gallery,
                "floorplans": floorplans,
                "description": description,
                "schoolDistrictName": schoolDistrictName,
                "propertyType": propertyType,
                "email": email,
                "phone": phone,
                "city": city,
                "county": county,
                "state": state,
                "zip":zip
            ]
            
            if let website = website {
                json["website"] = website
            }
            if let video = video {
                json["video"] = video
            }
            
            json += extendedFields
        }
        return json
    }
}

extension Listing: RESTEntity {
    var href: URL? {
        return ListingResource.idRoute.absoluteURLString.replacingOccurrences(of: "{id}", with: "\(id)").urlValue!
    }
    
    var links: [String:URL] {
        return [
            "requestInfo":ListingResource.informationRequestRoute.absoluteURLString.replacingOccurrences(of: "{id}", with: "\(id)").urlValue!,
            "builder":BuilderResource.idRoute.absoluteURLString.replacingOccurrences(of: "{id}", with: "\(builderId)").urlValue!,
            "gallery":ListingResource.galleryRoute.absoluteURLString.replacingOccurrences(of: "{id}", with: "\(id)").urlValue!,
            "floorplans":ListingResource.floorplansRoute.absoluteURLString.replacingOccurrences(of: "{id}", with: "\(id)").urlValue!
        ]
    }
}

extension Listing {
    // MARK: - Routes
    class func findListings(in region: MapRegion, in database: Database = Database(), sparseResults: Bool = true, completion: @escaping ([Listing]?)->()) {
        // Construct SQL
        let listingColumns = (sparseResults ? sparseColumns : allColumns)
        let listingQueryColumns = listingColumns.map({"listings.\($0)"})
        let builderQueryColumns = Builder.columns.map({"builders.\($0) as builders_\($0)"})
        let columns = (listingQueryColumns + builderQueryColumns).joined(separator: ",")
        let statement =
            "SELECT \(columns) " +
            "FROM listings " +
            "LEFT JOIN builders ON builders.id = listings.builderID " +
            "WHERE active > 0 " +
            "AND ((lat BETWEEN \(region.latitudeBegin) AND \(region.latitudeEnd)) AND (lng BETWEEN \(region.longitudeBegin) AND \(region.longitudeEnd)))"
        
        // Execute query
        fetchListings(from: database, withStatement: statement, sparseResults: sparseResults, completion: completion)
    }
    
    class func getListing(byId id: Int, in database: Database = Database(), completion: @escaping ([Listing]?)->()) {
        let listingQueryColumns = allColumns.map({"listings.\($0)"})
        let builderQueryColumns = Builder.columns.map({"builders.\($0) as builders_\($0)"})
        let columns = (listingQueryColumns + builderQueryColumns).joined(separator: ",")
        let statement =
            "SELECT \(columns) " +
            "FROM listings " +
            "LEFT JOIN builders ON builders.id = listings.builderID " +
            "WHERE listings.id = \(id)"
        fetchListings(from: database, withStatement: statement, sparseResults: false, completion: completion)
    }
    
    class func fetchFeaturedListings(in database: Database = Database(), completion: @escaping ([Listing]?)->()) {
        let listingQueryColumns = allColumns.map({"listings.\($0)"})
        let builderQueryColumns = Builder.columns.map({"builders.\($0) as builders_\($0)"})
        let columns = (listingQueryColumns + builderQueryColumns).joined(separator: ",")
        let statement =
            "SELECT \(columns) " +
            "FROM listings " +
            "LEFT JOIN builders ON builders.id = listings.builderID " +
            "WHERE listings.active > 1"
        fetchListings(from: database, withStatement: statement, sparseResults: true, completion: completion)
    }
    
    class func fetchListings(withBuilderId id: Int, in database: Database = Database(), completion: @escaping ([Listing]?)->()) {
        let statement =
            "SELECT \(allColumns.joined(separator: ",")) " +
            "FROM listings " +
            "WHERE listings.builderID = \(id) " +
            "AND active > 0"
        fetchListings(from: database, withStatement: statement, sparseResults: true, completion: completion)
    }
    
    class func requestInformationForListing(withId id: Int, payload: String, in database: Database = Database()) {
        let timestamp = Int(Date().timeIntervalSince1970)
        // NOTE: Square brackets around payload are for legacy database schema compatibility with scripts and other parts of the application
        let statement =
            "INSERT INTO requests (ts, data) " +
            "VALUES (\(timestamp), '[\(payload)]')"
        database.performQuery(statement: statement) { (results) in
            NSLog("Inserted stuff?")
        }
    }

    
    // MARK: - Reuseable Helpers
    private class func fetchListings(from database: Database, withStatement statement: String, sparseResults: Bool, completion: @escaping ([Listing]?)->()) {
        database.performQuery(statement: statement, completion: { results in
            guard let results = results else {
                NSLog("Error fetching listings")
                completion(nil)
                return
            }
            let listings = parseListings(fromResults: results, sparseResults: sparseResults)
            if !sparseResults {
                // TODO: Image fetching is super slow/expensive since there is so much bad data in the database. Clear some shit out.
                let listingIds = listings.map({$0.id})
                let imagesGroup = DispatchGroup()
                imagesGroup.enter()
                Image.findImages(withListingIds: listingIds, type: .gallery, in: database, completion: { images in
                    guard let images = images else {
                        NSLog("Error fetching gallery")
                        imagesGroup.leave()
                        return
                    }
                    listings.forEach({ listing in
                        listing.gallery = images[listing.id] ?? listing.gallery
                    })
                    imagesGroup.leave()
                })
                imagesGroup.enter()
                Image.findImages(withListingIds: listingIds, type: .floorplan, completion: { images in
                    guard let images = images else {
                        NSLog("Error fetching floorplans")
                        imagesGroup.leave()
                        return
                    }
                    listings.forEach({ listing in
                        listing.floorplans = images[listing.id] ?? listing.floorplans
                    })
                    imagesGroup.leave()
                })
                imagesGroup.notify(queue: DispatchQueue(label: "imagesQueue"), execute: {
                    completion(listings)
                })
            } else {
                completion(listings)
            }
        })
    }
    
    private class func parseListings(fromResults results: Database.SQLView, sparseResults: Bool) -> [Listing] {
        var listings: [Listing] = []
        var builderCache: [Int: Builder] = [:]
        let listingColumns = (sparseResults ? sparseColumns : allColumns)
        let listingColumnCount = listingColumns.count
        let builderColumnCount = Builder.columns.count
        for row in results {
            // Parse the listing
            var listing: Listing
            let listingDict = Dictionary<String, String>.combining(keyArray: listingColumns, valueArray: Array(row[0..<listingColumnCount]))
            if sparseResults {
                listing = Listing(withSparseResult: listingDict)
            } else {
                listing = Listing(withResult: listingDict)
            }
            
            // A builder join was executed
            if row.count > listingColumns.count {
                // Parse and cache the builder
                let builderId = row[listingColumnCount]?.intValue ?? -1
                if let builder = builderCache[builderId] {
                    listing.builder = builder
                } else {
                    let builderDict = Dictionary<String, String>.combining(keyArray: Builder.columns, valueArray: Array(row[listingColumnCount..<listingColumnCount+builderColumnCount]))
                    let builder = Builder(withResult: builderDict)
                    listing.builder = builder
                    builderCache[builderId] = builder
                }
            }
            listings.append(listing)
        }
        return listings
    }
}
