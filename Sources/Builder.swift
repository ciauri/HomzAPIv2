//
//  Builder.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import Foundation
import PerfectLib

class Builder: JSONConvertibleObject {
    static let columns = ["id", "builder", "phone", "fax", "email", "paid", "photo", "website", "ads_enabled"]
    static let computedColumns = ["activeListingCount" : "count(distinct l.id) as activeListingCount"]
    
    var id: Int = -1
    var name: String = ""
    var logo: URL?
    var website: URL?
    var phone: String = ""
    var fax: String = ""
    var email: String = ""
    var paid: Bool = false
    var adsEnabled: Bool = true
    var activeListingCount: Int = 0
        
    init(withResult result: [String:String]) {
        super.init()
        id = result["id"]?.intValue ?? id
        name = result["builder"] ?? name
        phone = result["phone"] ?? phone
        fax = result["fax"] ?? fax
        email = result["email"] ?? email
        adsEnabled = result["ads_enabled"]?.intValue == 1
        paid = result["paid"]?.intValue == 1
        website = result["website"]?.urlValue
        logo = result["photo"]?.urlValue
        activeListingCount = result["activeListingCount"]?.intValue ?? 0
    }
    
    override func getJSONValues() -> [String : Any] {
        var json: [String:Any] = [
            "id": id,
            "href": href ?? "",
            "links": links,
            "name": name,
            "phone": phone,
            "fax": fax,
            "email": email,
            "paid": paid,
            "ads_enabled": adsEnabled,
            "activeListingCount": activeListingCount
        ]
        if let logo = logo {
            json["logo"] = logo
        }
        if let website = website {
            json["website"] = website
        }
        return json
    }
}

extension Builder: RESTEntity {
    var href: URL? {
        return NewHomzAPI.shared.baseURL.appendingPathComponent(BuilderResource.idRoute.uri.replacingOccurrences(of: "{id}", with: "\(id)"), isDirectory: false)
    }
    
    var links: [String:URL] {
        return ["listings":href!.appendingPathComponent("listings", isDirectory: false)]
    }
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
                let builder = Builder(withResult: builderDict)
                builders.append(builder)
            }
            completion(builders)
        })
    }
}
