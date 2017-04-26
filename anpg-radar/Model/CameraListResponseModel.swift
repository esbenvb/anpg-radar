//
// Created by Esben von Buchwald on 23/11/2016.
// Copyright (c) 2016 ___FULLUSERNAME___. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case missing(String)
    case failure(String)
}

struct CameraListResponseModel {
    let elements: [CameraListItem]
}

extension CameraListResponseModel {
    init?(json: [String: Any]) {
        guard let elements = json["elements"] as? [[String: Any]] else {return nil}
        do {
            self.elements = try elements.map({ (item: [String : Any]) -> CameraListItem in
                guard let listItem = CameraListItem(json: item) else {
                    throw NetworkError.missing("elements")
                }
                return listItem
            })
        } catch {
            return nil
        }
    }
    
    static func load(completion: @escaping (_ elements: [CameraListItem])->(), failure: ((Error?)->())? = nil) {
        #if (arch(i386) || arch(x86_64))
            let feedUrlString = "http://localhost:8000/data.json"
        #else
            let feedUrlString = "http://anpg.amokk.dk/files/data.json"
        #endif
        
        guard let url = URL(string: feedUrlString) else {return}
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                failure?(error)
                return
            }
            do {
                if let httpResponse = response as? HTTPURLResponse,  let expires = httpResponse.allHeaderFields["Expires"] as? String {
                    let expiresDate = DateFormatter.dateFromIso2616(from: expires)
                    UserDefaults.standard.set(expiresDate, forKey: Constants.cameraListExpiresKey)
                }
                
                guard let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {return}
                let responseModel = CameraListResponseModel(json: parsedData)
                let elements = responseModel?.elements ?? []
                completion(elements)

            } catch {
                failure?(error)
            }
            }.resume()
        
        
    }
}

extension DateFormatter {
    static func dateFromIso2616(from string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return dateFormatter.date(from: string)
    }
}
