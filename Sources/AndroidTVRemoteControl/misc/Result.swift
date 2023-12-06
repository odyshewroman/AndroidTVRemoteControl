//
//  Result.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

public enum Result<T> {
    case Result(T)
    case Error(AndroidTVRemoteControlError)
}
