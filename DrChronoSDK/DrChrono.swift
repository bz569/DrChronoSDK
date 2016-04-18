
//
//  DrChrono.swift
//  DrchronoSDK
//
//  Created by Boxuan Zhang on 4/13/16.
//  Copyright © 2016 drchrono. All rights reserved.
//

import Foundation
import OAuthSwift
import Swifter

public class DrChrono: NSObject {

    public typealias TokenSuccessHandler = OAuthSwift.TokenSuccessHandler
    public typealias FailureHandler = (error: NSError) -> Void

    public typealias HTTPSuccessHandler = (json: AnyObject, response: NSURLResponse) -> ()
    public typealias HTTPFailureHandler = (error: NSError) -> ()

    public var localHTTPPort: Int = 9080
    public var authorizeURLHandler: OAuthSwiftURLHandlerType?
    public var oauth: OAuth2Swift?

    public static let shared = DrChrono()
    public static func getSafariURLHandler(viewController: UIViewController) -> OAuthSwiftURLHandlerType? {
        if #available(iOS 9, *) {
            return SafariURLHandler(viewController: viewController)
        } else { return nil }
    }

    private let baseURL = "https://drchrono.com"
    private var clientID: String?
    private var clientSecret: String?

    override init() {
         super.init()
    }

    public init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        super.init()
        self.oauth = OAuth2Swift(
            consumerKey: clientID,
            consumerSecret: clientSecret,
            authorizeUrl: "\(baseURL)/o/authorize",
            accessTokenUrl: "\(baseURL)o/token/",
            responseType: "code")
    }

    public func set(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.oauth = OAuth2Swift(
            consumerKey: clientID,
            consumerSecret: clientSecret,
            authorizeUrl: "\(baseURL)/o/authorize",
            accessTokenUrl: "\(baseURL)/o/token/",
            responseType: "code")
    }

    public func authentication(callBackURLScheme: String, scope: String, state: String, params: [String: String] = [:], success: TokenSuccessHandler, failure: FailureHandler) {
        guard let oauthSwift = oauth else {
            failure(error: NSError(domain: "DrchronoSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "DrChrono SDK has Not been set"]))
            return
        }

        guard let callBackURL = NSURL(string: "http://localhost:\(localHTTPPort)/\(callBackURLScheme)") else {
            failure(error: NSError(domain: "DrchronoSDK", code: -2, userInfo: [NSLocalizedDescriptionKey: "Call Back URL Scheme Error"]))
            return
        }

        // Start a temporary HTTP server to handle oauth redirect
        let server = LocalHTTP(redirectURLScheme: callBackURLScheme, port: localHTTPPort)
        do {
            try server.start()

            if let handler = authorizeURLHandler {
                oauthSwift.authorize_url_handler = handler
            }

            oauthSwift.authorizeWithCallbackURL(
                callBackURL,
                scope: scope,
                state: state,
                params: params,
                success: { (credential, response, parameters) in
                    server.stop()
                    success(credential: credential, response: response, parameters: parameters)
                }, failure: { (error) in
                    server.stop()
                    failure(error: NSError(domain: "DrchronoSDK", code: -4, userInfo: error.userInfo))
            })
        } catch let httpError as NSError {
            failure(error: NSError(domain: "DrchronoSDK", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot set up HTTP server to handle redirect URL: \(httpError.localizedDescription)"]))
        }
    }

}

// MARK: - Request
extension DrChrono {
    public func request(
        endPoint: String,
        method: OAuthSwiftHTTPRequest.Method,
        parameters: [String: String] = [:],
        headers: [String: String]? = nil,
        checkTokenExpiration: Bool = true,
        success: HTTPSuccessHandler?,
        failure: HTTPFailureHandler?) {

        guard let oauth = oauth else {
            failure?(error: NSError(domain: "DrchronoSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "DrChrono SDK has Not been set"]))
            return
        }

        let urlString = baseURL + endPoint

        oauth.client.request(
            urlString,
            method: method,
            parameters: parameters,
            headers: headers,
            checkTokenExpiration: checkTokenExpiration,
            success: { (data, response) in
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    success?(json: json, response: response)
                } catch let error as NSError {
                    failure?(error: error)
                }

            },
            failure: failure
        )
    }

    public func get(endPoint: String,
             parameters: [String: String] = [:],
             headers: [String: String]? = nil,
             checkTokenExpiration: Bool = true,
             success: HTTPSuccessHandler?,
             failure: HTTPFailureHandler?) {

        request(endPoint, method: .GET, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public func post(endPoint: String,
              parameters: [String: String] = [:],
              headers: [String: String]? = nil,
              checkTokenExpiration: Bool = true,
              success: HTTPSuccessHandler?,
              failure: HTTPFailureHandler?) {

        request(endPoint, method: .POST, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public func put(endPoint: String,
             parameters: [String: String] = [:],
             headers: [String: String]? = nil,
             checkTokenExpiration: Bool = true,
             success: HTTPSuccessHandler?,
             failure: HTTPFailureHandler?) {

        request(endPoint, method: .PUT, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public func delete(endPoint: String,
                parameters: [String: String] = [:],
                headers: [String: String]? = nil,
                checkTokenExpiration: Bool = true,
                success: HTTPSuccessHandler?,
                failure: HTTPFailureHandler?) {

        request(endPoint, method: .DELETE, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public func patch(endPoint: String,
               parameters: [String: String] = [:],
               headers: [String: String]? = nil,
               checkTokenExpiration: Bool = true,
               success: HTTPSuccessHandler?,
               failure: HTTPFailureHandler?) {

        request(endPoint, method: .PATCH, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public var token: (token: String, secretToken: String)? {
        guard let oauth = oauth else { return nil }
        return (oauth.client.credential.oauth_token, oauth.client.credential.oauth_token_secret)
    }

    public var credential: OAuthSwiftCredential? { return oauth?.client.credential }

    public func restoreToken(token: String, secretToken: String) {
        oauth?.client.credential.oauth_token = token
        oauth?.client.credential.oauth_token_secret = secretToken
    }

}

// MARK: - Convenient Singleton Methods
extension DrChrono {

    public static func set(clientID: String, clientSecret: String) {
        shared.set(clientID, clientSecret: clientSecret)
    }

    public static var authorizeURLHandler: OAuthSwiftURLHandlerType? {
        set { shared.authorizeURLHandler = newValue }
        get { return shared.authorizeURLHandler }
    }

    public static func authentication(callBackURLScheme: String, scope: String, state: String, params: [String: String] = [:], success: TokenSuccessHandler, failure: FailureHandler) {
        shared.authentication(callBackURLScheme, scope: scope, state: state, success: success, failure: failure)
    }

    public static func request(
        endPoint: String,
        method: OAuthSwiftHTTPRequest.Method,
        parameters: [String: String] = [:],
        headers: [String: String]? = nil,
        checkTokenExpiration: Bool = true,
        success: HTTPSuccessHandler?,
        failure: HTTPFailureHandler?) {
            shared.request(endPoint, method: method, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public static func get(endPoint: String,
                    parameters: [String: String] = [:],
                    headers: [String: String]? = nil,
                    checkTokenExpiration: Bool = true,
                    success: HTTPSuccessHandler?,
                    failure: HTTPFailureHandler?) {

        shared.request(endPoint, method: .GET, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public static func post(endPoint: String,
              parameters: [String: String] = [:],
              headers: [String: String]? = nil,
              checkTokenExpiration: Bool = true,
              success: HTTPSuccessHandler?,
              failure: HTTPFailureHandler?) {

        shared.request(endPoint, method: .POST, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public static func put(endPoint: String,
             parameters: [String: String] = [:],
             headers: [String: String]? = nil,
             checkTokenExpiration: Bool = true,
             success: HTTPSuccessHandler?,
             failure: HTTPFailureHandler?) {

        shared.request(endPoint, method: .PUT, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public static func delete(endPoint: String,
                parameters: [String: String] = [:],
                headers: [String: String]? = nil,
                checkTokenExpiration: Bool = true,
                success: HTTPSuccessHandler?,
                failure: HTTPFailureHandler?) {

        shared.request(endPoint, method: .DELETE, parameters: parameters, headers: headers, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public static var token: (token: String, secretToken: String)? {
       return shared.token
    }

    public static var credential: OAuthSwiftCredential? { return shared.credential }

    public static func restoreToken(token: String, secretToken: String) {
        shared.restoreToken(token, secretToken: secretToken)
    }
}

class LocalHTTP {

    let server: HttpServer
    let redirectURLScheme: String
    let port: UInt16

    init(redirectURLScheme: String, port: Int = 9080) {
        self.redirectURLScheme = redirectURLScheme
        self.port = UInt16(port)
        self.server = HttpServer()

        self.server["/\(redirectURLScheme)"] = { r in
            let code = r.queryParams.filter { $0.0 == "code" }.first?.1
            let codeParam = code.map { "code=\($0)" } ?? "error=access_denied"
            let state = r.queryParams.filter { $0.0 == "state" }.first?.1
            let stateParam = state.map { "state=\($0)" } ?? ""
            let params = [codeParam, stateParam].joinWithSeparator("&")
            return .MovedPermanently("\(redirectURLScheme)://oauth?\(params)")
        }
    }

    func start() throws { try server.start(port) }
    func stop() { server.stop() }
}











