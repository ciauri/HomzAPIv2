//
//  BuilderResource.swift
//  NewHomzAPI
//
//  Created by Stephen Ciauri on 4/19/17.
//
//

import Foundation
import PerfectHTTP
import PerfectLib

class BuilderResource {
    // MARK: - Routes
    
    // MARK: Root Routes
    static let allRoute = Route(method: .get, uri: "/builders", handler: allHandler)
    static let featuredRoute = Route(method: .get, uri: "/builders/featured", handler: featuredHandler)
    
    // MARK: Delivered Routes
    static let idRoute = Route(method: .get, uri: "/builder/{id}", handler: idHandler)
    static let listingsRoute = Route(method: .get, uri: "/builder/{id}/listings", handler: listingsHandler)
    
    class func allHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
//        response.setHeader(.cacheControl, value: "max-age=3600")
        getBuilders(response: response)
    }
    
    class func idHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
//        response.setHeader(.cacheControl, value: "max-age=3600")
        guard let id = request.urlVariables["id"]?.intValue else {
            response.completed(status: .badRequest)
            return
        }
        getBuilder(byId: id, response: response)
    }
    
    class func featuredHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
//        response.setHeader(.cacheControl, value: "max-age=3600")
        getFeaturedBuilders(response: response)
    }
    
    class func listingsHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
//        response.setHeader(.cacheControl, value: "max-age=3600")
        guard let id = request.urlVariables["id"]?.intValue else {
            response.completed(status: .badRequest)
            return
        }
        getListingsForBuilder(with: id, response: response)
    }
    
    
    // MARK: - Handler Helpers
    class func getBuilder(byId id: Int, response: HTTPResponse) {
        Builder.getBuilder(byId: id) { (builders) in
            guard let builders = builders else {
                NSLog("Error fetching builder")
                response.completed(status: .internalServerError)
                return
            }
            
            guard let builder = builders.first else {
                NSLog("No builder found with id \(id)")
                response.appendBody(jsonRepresentable: [])
                response.completed(status: .ok)
                return
            }
            do {
                try response.appendBody(encodable: builder)
            } catch {
                NSLog("Failed to serialize builders")
                response.completed(status: .internalServerError)
                return
            }
            response.completed(status: .ok)
        }
    }
    
    class func getFeaturedBuilders(response: HTTPResponse) {
        Builder.getFeaturedBuilders() { (builders) in
            guard let builders = builders else {
                NSLog("Error fetching builder")
                response.completed(status: .internalServerError)
                return
            }
            let builderList = BuilderList(builders: builders)
            do {
                try response.appendBody(encodable: builderList)
            } catch {
                NSLog("Failed to serialize builders")
                response.completed(status: .internalServerError)
                return
            }
            
            response.completed(status: .ok)
        }
    }
    
    class func getBuilders(response: HTTPResponse) {
        Builder.getBuilders() { (builders) in
            guard let builders = builders else {
                NSLog("Error fetching builder")
                response.completed(status: .internalServerError)
                return
            }
            let builderList = BuilderList(builders: builders)
            do {
                try response.appendBody(encodable: builderList)
            } catch {
                NSLog("Failed to serialize builders")
                response.completed(status: .internalServerError)
                return
            }
            
            response.completed(status: .ok)
        }
    }
    
    class func getListingsForBuilder(with id: Int, response: HTTPResponse) {
        Listing.fetchListings(withBuilderId: id) { (listings) in
            guard let listings = listings else {
                NSLog("Error fetching listings for builder id \(id)")
                response.completed(status: .internalServerError)
                return
            }
            do {
                try response.appendBody(encodable: ListingList(listings: listings))
            } catch {
                NSLog("Failed to serialize listings")
                response.completed(status: .internalServerError)
                return
            }
            response.completed(status: .ok)
        }
    }
    
}


extension BuilderResource: Resource {
    class var routes: [Route] {
        return [allRoute,featuredRoute,idRoute,listingsRoute]
    }
    class var rootRoutes: [Route] {
        return [allRoute, featuredRoute]
    }
}
