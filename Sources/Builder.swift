//
//  Builder.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import Foundation
import PerfectLib

class Builder {
    static let columns = ["id", "builder", "phone", "fax", "email", "paid", "photo", "website", "ads_enabled"]
    static let computedColumns = ["activeListingCount" : "count(distinct l.id) as activeListingCount"]
    
    var id: Int
    var name: String
    var logo: URL?
    var website: URL?
    var phone: String?
    var fax: String?
    var email: String?
    var paid: Bool = false
    var adsEnabled: Bool = true
    var activeListingCount: Int?
        
    init?(withResult result: [String:String]) {
        guard let id = result["id"]?.intValue,
            let name = result["builder"] else {
                return nil
        }
        self.id = id
        self.name = name
        phone = result["phone"]
        fax = result["fax"]
        email = result["email"]
        adsEnabled = result["ads_enabled"]?.intValue == 1
        paid = result["paid"]?.intValue == 1
        website = result["website"]?.urlValue
        logo = result["photo"]?.urlValue
        activeListingCount = result["activeListingCount"]?.intValue
    }
}

extension Builder: Encodable {
    fileprivate enum CodingKeys: String, CodingKey {
        case id
        case name
        case logo
        case website
        case phone
        case fax
        case email
        case paid
        case adsEnabled = "ads_enabled"
        case activeListingCount
        case links
        case href
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(links, forKey: .links)
        try container.encode(href, forKey: .href)
        
        try container.encode(name, forKey: .name)
        try container.encode(logo, forKey: .logo)
        try container.encode(website, forKey: .website)
        try container.encode(phone, forKey: .phone)
        try container.encode(fax, forKey: .fax)
        try container.encode(email, forKey: .email)
        try container.encode(paid, forKey: .paid)
        try container.encode(adsEnabled, forKey: .adsEnabled)
        try container.encodeIfPresent(activeListingCount, forKey: .activeListingCount)
    }
}

extension Builder: RESTEntity {
    var href: URL? {
        return NewHomzAPI.shared.baseURL.appendingPathComponent(BuilderResource.idRoute.uri.replacingOccurrences(of: "{id}", with: "\(id ?? -1)"), isDirectory: false)
    }
    
    var links: [String:URL] {
        return ["listings":href!.appendingPathComponent("listings", isDirectory: false)]
    }
}

struct BuilderList: Encodable {
    let builders: [Builder]
}

// MARK: - Routes
extension Builder {

    class func getBuilder(byId id: Int, in database: Database = Database(), completion: @escaping ([Builder]?)->()) {
        let statement =
            "SELECT \(columns.joined(separator: ",")), (SELECT COUNT(1) FROM listings WHERE builderId = builders.id AND active > 0) AS activeListingCount " +
            "FROM builders " +
            "WHERE id = \(id)"
        
        fetchBuilders(from: database, withStatement: statement, completion: completion)
    }
    
    class func getFeaturedBuilders(in database: Database = Database(), completion: @escaping ([Builder]?)->()) {
        let builderQueryColumns = columns.map({"builders.\($0) as \($0)"})
        let queryColumns = (builderQueryColumns + computedColumns.values).joined(separator: ",")
        let statement =
            "SELECT \(queryColumns) " +
            "FROM builders " +
            "INNER JOIN listings l " +
            "ON builders.id = l.builderId " +
            "WHERE l.active > 0 AND builders.paid = 1 " +
            "GROUP BY builders.id"
        
        fetchBuilders(from: database, withStatement: statement, completion: completion)
    }
    
    class func getBuilders(in database: Database = Database(), completion: @escaping ([Builder]?)->()) {
        let builderQueryColumns = columns.map({"builders.\($0) as \($0)"})
        let queryColumns = (builderQueryColumns + computedColumns.values).joined(separator: ",")
        let statement =
            "SELECT \(queryColumns) " +
            "FROM builders " +
            "INNER JOIN listings l " +
            "ON builders.id = l.builderId " +
            "WHERE l.active > 0 " +
            "GROUP BY builders.id"
        
        fetchBuilders(from: database, withStatement: statement, completion: completion)
    }
    
    
    // MARK: - Reuseable Helpers
    private class func fetchBuilders(from database: Database, withStatement statement: String, completion: @escaping ([Builder]?)->()) {
        database.performQuery(statement: statement, completion: { results in
            guard let results = results else {
                NSLog("Error fetching builders")
                completion(nil)
                return
            }
            var builders: [Builder] = []
            for row in results {
                let builderDict = Dictionary<String, String>.combining(keyArray: columns + computedColumns.keys, valueArray: row)
                if let builder = Builder(withResult: builderDict) {
                    builders.append(builder)
                }
            }
            completion(builders)
        })
    }
}
