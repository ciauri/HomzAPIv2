//
//  Listings.swift
//  NewHomzAPI
//
//  Created by Stephen Ciauri on 3/30/17.
//
//

import Foundation
import PerfectHTTP
import PerfectLib

class ListingResource {
    static let mapRoute = Route(method: .get, uri: "/listings", handler: mapHandler)
    static let featuredRoute = Route(method: .get, uri: "/listings/featured", handler: featuredHandler)
    static let idRoute = Route(method: .get, uri: "/listing/{id}", handler: listingHandler)
    static let galleryRoute = Route(method: .get, uri: "/listing/{id}/gallery", handler: galleryRequestHandler)
    static let floorplansRoute = Route(method: .get, uri: "/listing/{id}/floorplans", handler: floorplanRequestHandler)
    static let informationRequestRoute = Route(method: .put, uri: "/listing/{id}/infoRequest", handler: informationRequestHandler)
    
    class var routes: [Route] {
        return [mapRoute,featuredRoute,idRoute, informationRequestRoute, floorplansRoute, galleryRoute]
    }
    
    // MARK: - Route Handlers
    class func mapHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        let params = request.queryParams.toDictionary
        guard
            let latStart = params["latStart"]?.doubleValue,
            let latStop = params["latStop"]?.doubleValue,
            let longStart = params["lonStart"]?.doubleValue,
            let longStop = params["lonStop"]?.doubleValue else {
                response.completed(status: .badRequest)
                return
        }
        let region = MapRegion(latitudeBegin: latStart, latitudeEnd: latStop, longitudeBegin: longStart, longitudeEnd: longStop)
        findListings(in: region, response: response)
    }
    
    class func listingHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        guard let id = request.urlVariables["id"]?.intValue else {
            response.completed(status: .badRequest)
            return
        }
        getListing(byId: id, response: response)
    }
    
    class func featuredHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        getFeaturedListings(response: response)
    }
    
    class func informationRequestHandler(request: HTTPRequest, response: HTTPResponse) {
        guard
            let id = request.urlVariables["id"]?.intValue,
            let bytes = request.postBodyBytes,
            let json = (try? JSONSerialization.jsonObject(with: Data(bytes), options: .allowFragments)) as? [String: String],
            let payload = json["data"]
            else {
            response.completed(status: .badRequest)
            return
        }
        requestInformation(withId: id, payload: payload, response: response)
    }
    
    class func galleryRequestHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        guard let id = request.urlVariables["id"]?.intValue else {
            response.completed(status: .badRequest)
            return
        }
        getImages(forListingId: id, type: .gallery, response: response)
    }
    
    class func floorplanRequestHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        guard let id = request.urlVariables["id"]?.intValue else {
            response.completed(status: .badRequest)
            return
        }
        getImages(forListingId: id, type: .floorplan, response: response)
    }
    
    // MARK: - Handler Helpers
    class func findListings(in region: MapRegion, response: HTTPResponse) {
        Listing.findListings(in: region, sparseResults: true, completion: { listings in
            guard let listings = listings else {
                NSLog("Error")
                response.completed(status: .internalServerError)
                return
            }
            response.appendBody(jsonRepresentable: ["listings":listings])
            response.completed(status: .ok)
        })
    }
    
    class func getListing(byId id: Int, response: HTTPResponse) {
        Listing.getListing(byId: id, completion: { listings in
            guard let listings = listings else {
                NSLog("Error fetching listing")
                response.completed(status: .internalServerError)
                return
            }
            response.appendBody(jsonRepresentable: listings.first ?? [])
            response.completed(status: .ok)
        })
    }
    
    class func getFeaturedListings(response: HTTPResponse) {
        Listing.fetchFeaturedListings(completion: { listings in
            guard let listings = listings else {
                NSLog("Error fetching listings")
                response.completed(status: .internalServerError)
                return
            }
            response.appendBody(jsonRepresentable: ["listings":listings])
            response.completed(status: .ok)
        })
    }
    
    class func requestInformation(withId id: Int, payload: String, response: HTTPResponse) {
        Listing.requestInformationForListing(withId: id, payload: payload)
        response.completed(status: .ok)
    }
    
    class func getImages(forListingId id: Int, type: Image.ImageType, response: HTTPResponse) {
        Image.findImages(forListingId: id, type: type, completion: { images in
            guard let images = images else {
                NSLog("Error fetching images")
                response.completed(status: .internalServerError)
                return
            }
            response.appendBody(jsonRepresentable: images)
            response.completed(status: .ok)
        })
    }
  
}

