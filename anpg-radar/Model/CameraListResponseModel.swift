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
}
