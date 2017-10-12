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

class Listing: Encodable {
    static let sparseColumns: [String] = ["id", "listing", "photo", "active", "lat", "lng", "builderID", "priceTxt", "priceLow", "priceHigh", "sqftLow", "sqftHigh", "bedLow", "bedHigh", "bathLow", "bathHigh"]
    static let detailColumns: [String] = ["propType", "city", "county", "state", "zip", "description", "email", "website", "phone", "vid", "schoolDistrictName"]
    static let allColumns: [String] = sparseColumns + detailColumns
    
    private var sparseEntity: Bool = true
    
    // Sparse properties
    var id: Int
    var name: String
    var builderId: Int
    var status: Status = .inactive
    var featuredPhoto: URL?
    var coordinate: Coordinate
    var priceText: String = "From the"
    var price: NumberRange
    var squareFootage: NumberRange
    var bedrooms: NumberRange
    var bathrooms: NumberRange
    
    // Detailed properties
    var builder: Builder?
    var description: String?
    var schoolDistrictName: String?
    var gallery: [Image]?
    var floorplans: [Image]?
    var propertyType: String?
    var email: String?
    var website: URL?
    var video: URL?
    var phone: String?
    var city: String?
    var county: String?
    var state: String?
    var zip: String?
    
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

    
    fileprivate enum CodingKeys: String, CodingKey {
        case id
        case links
        case href
        
        case name
        case builderId = "builderID"
        case coordinate
        case price
        case priceText
        case squareFootage
        case bedrooms
        case bathrooms
        case status
        case featuredPhoto
        
        case builder
        case gallery
        case floorplans
        case description
        case schoolDistrictName
        case propertyType
        case email
        case phone
        case city
        case county
        case state
        case zip
        case website
        case video
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(links, forKey: .links)
        try container.encode(href, forKey: .href)
        
        try container.encode(name, forKey: .name)
        try container.encode(builderId, forKey: .builderId)
        try container.encode(coordinate, forKey: .coordinate)
        try container.encode(price, forKey: .price)
        try container.encode(priceText, forKey: .priceText)
        try container.encode(squareFootage, forKey: .squareFootage)
        try container.encode(bedrooms, forKey: .bedrooms)
        try container.encode(bathrooms, forKey: .bathrooms)
        try container.encode(status.jsonValue, forKey: .status)
        try container.encodeIfPresent(featuredPhoto, forKey: .featuredPhoto)
        
        try container.encodeIfPresent(builder, forKey: .builder)
        try container.encodeIfPresent(gallery, forKey: .gallery)
        try container.encodeIfPresent(floorplans, forKey: .floorplans)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(schoolDistrictName, forKey: .schoolDistrictName)
        try container.encodeIfPresent(propertyType, forKey: .propertyType)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(county, forKey: .county)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(zip, forKey: .zip)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(video, forKey: .video)
    }

    init?(withSparseResult result: [String:String]) {
        guard let id = result["id"]?.intValue,
            let builderId = result["builderID"]?.intValue,
            let name = result["listing"],
            let lat = result["lat"]?.doubleValue,
            let long = result["lng"]?.doubleValue,
            let priceLow = result["priceLow"]?.floatValue,
            let priceHigh = result["priceHigh"]?.floatValue,
            let squareFootLow = result["sqftLow"]?.floatValue,
            let squareFootHigh = result["sqftHigh"]?.floatValue,
            let bedLow = result["bedLow"]?.floatValue,
            let bedHigh = result["bedHigh"]?.floatValue,
            let bathLow = result["bathLow"]?.floatValue,
            let bathHigh = result["bathHigh"]?.floatValue,
            let statusInt = result["active"]?.intValue,
            let status = Status(rawValue: statusInt) else {
                NSLog("Failed to serialize listing from database result: \(result)")
                return nil
        }

        self.id = id
        self.builderId = builderId
        self.name = name
        coordinate = Coordinate(latitude: lat, longitude: long)
        price = NumberRange(min: priceLow, max: priceHigh)
        squareFootage = NumberRange(min: squareFootLow, max: squareFootHigh)
        bedrooms = NumberRange(min: bedLow, max: bedHigh)
        bathrooms = NumberRange(min: bathLow, max: bathHigh)
        self.status = status
        
        if let priceText = result["priceText"], priceText != "" {
            self.priceText = priceText
        }
        self.featuredPhoto = result["photo"]?.urlValue
    }
    
    
    convenience init?(withResult result: [String:String]) {
        self.init(withSparseResult: result)
        sparseEntity = false
        propertyType = result["propType"]
        description = result["description"]
        email = result["email"]
        website = result["website"]?.urlValue
        phone = result["phone"]
        video = result["vid"]?.urlValue
        schoolDistrictName = result["schoolDistrictName"]
        city = result["city"]
        county = result["county"]
        state = result["state"]
        zip = result["zip"]
    }
}

struct ListingList: Encodable {
    let listings: [Listing]
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
    class func findListings(in region: MapRegion, in database: Database = Database(), sparseListings: Bool = true, completion: @escaping ([Listing]?)->()) {
        // Construct SQL
        let listingColumns = (sparseListings ? sparseColumns : allColumns)
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
        fetchListings(from: database, withStatement: statement, withImages: false, sparseListing: sparseListings, joinedWithBuilder: true, completion: completion)
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
        fetchListings(from: database, withStatement: statement, withImages: true, sparseListing: false, joinedWithBuilder: true, completion: completion)
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
        fetchListings(from: database, withStatement: statement, withImages: false, sparseListing: false, joinedWithBuilder: true, completion: completion)
    }
    
    class func fetchListings(withBuilderId id: Int, in database: Database = Database(), completion: @escaping ([Listing]?)->()) {
        let statement =
            "SELECT \(allColumns.joined(separator: ",")) " +
            "FROM listings " +
            "WHERE listings.builderID = \(id) " +
            "AND active > 0"
        fetchListings(from: database, withStatement: statement, withImages: false, sparseListing: false, joinedWithBuilder: false, completion: completion)
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
    private class func fetchListings(from database: Database, withStatement statement: String, withImages: Bool, sparseListing: Bool, joinedWithBuilder joined: Bool, completion: @escaping ([Listing]?)->()) {
        database.performQuery(statement: statement, completion: { results in
            guard let results = results else {
                NSLog("Error fetching listings")
                completion(nil)
                return
            }
            let listings = parseListings(fromResults: results, sparseListing: sparseListing, joinedWithBuilder: joined)
            if withImages {
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
    
    private class func parseListings(fromResults results: Database.SQLView, sparseListing: Bool, joinedWithBuilder: Bool) -> [Listing] {
        var listings: [Listing] = []
        var builderCache: [Int: Builder] = [:]
        let listingColumns = (sparseListing ? sparseColumns : allColumns)
        let listingColumnCount = listingColumns.count
        let builderColumnCount = Builder.columns.count
        for row in results {
            // Parse the listing
            var listing: Listing?
            let listingDict = Dictionary<String, String>.combining(keyArray: listingColumns, valueArray: Array(row[0..<listingColumnCount]))
            if sparseListing {
                listing = Listing(withSparseResult: listingDict)
            } else {
                listing = Listing(withResult: listingDict)
            }
            
            if let listing = listing {
                // A builder join was executed
                if joinedWithBuilder {
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
        }
        return listings
    }
}
