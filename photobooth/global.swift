//
//  global.swift
//  photobooth
//
//  Created by Brandon Yen on 2/22/24.
//

import Foundation
import UIKit

// Global variables
var cameraIP = "" // Camera IP address and port number
let numTemplates = 7

// Areas to draw the four taken images in, for each template
let areaSizeSketch: [CGRect] = [
    CGRect(x: 174, y: 204, width: 716, height: 1075),
    CGRect(x: 910, y: 204, width: 716, height: 1075),
    CGRect(x: 174, y: 1298.66, width: 716, height: 1075),
    CGRect(x: 910, y: 1298.66, width: 716, height: 1075)
]
let areaSizeKakao: [CGRect] = [
    CGRect(x: 220.75, y: 133.81, width: 671, height: 1006),
    CGRect(x: 909.94, y: 133.81, width: 671, height: 1006),
    CGRect(x: 220.75, y: 1158.72, width: 671, height: 1006),
    CGRect(x: 909.94, y: 1158.72, width: 671, height: 1006)
]
let areaSizeKakao2: [CGRect] = [
    CGRect(x: 220.75, y: 457.84, width: 671, height: 1006),
    CGRect(x: 909.94, y: 457.84, width: 671, height: 1006),
    CGRect(x: 220.75, y: 1482.72, width: 671, height: 1006),
    CGRect(x: 909.94, y: 1482.72, width: 671, height: 1006)
]
let areaSizeKakao3: [CGRect] = [
    CGRect(x: 219.75, y: 131.84, width: 671, height: 1006),
    CGRect(x: 908.94, y: 131.84, width: 671, height: 1006),
    CGRect(x: 219.75, y: 1159.72, width: 671, height: 1006),
    CGRect(x: 908.94, y: 1159.72, width: 671, height: 1006)
]
let areaSizePhotocards: [CGRect] = [
    CGRect(x: 160, y: 366, width: 618, height: 928),
    CGRect(x: 1020, y: 366, width: 618, height: 928),
    CGRect(x: 160, y: 1495, width: 618, height: 928),
    CGRect(x: 1020, y: 1495, width: 618, height: 928)
]
let areaSizeKakaoPreview: [CGRect] = [
    CGRect(x: 220.75, y: 181.84, width: 671, height: 1006),
    CGRect(x: 909.94, y: 181.84, width: 671, height: 1006),
    CGRect(x: 220.75, y: 1206.72, width: 671, height: 1006),
    CGRect(x: 909.94, y: 1206.72, width: 671, height: 1006)
]
let areaSizeKakao3Preview: [CGRect] = [
    CGRect(x: 219.75, y: 181.84, width: 671, height: 1006),
    CGRect(x: 908.94, y: 181.84, width: 671, height: 1006),
    CGRect(x: 219.75, y: 1206.72, width: 671, height: 1006),
    CGRect(x: 908.94, y: 1206.72, width: 671, height: 1006)
]
let areaSizeKodak: [CGRect] = [
    CGRect(x: 80, y: 174, width: 729, height: 1123),
    CGRect(x: 992, y: 174, width: 729, height: 1123),
    CGRect(x: 80, y: 1350, width: 729, height: 1123),
    CGRect(x: 992, y: 1350, width: 729, height: 1123)
]

let topImageTemplate = [ // Overlay template array (for actual print)
    UIImage(named: "PhotoboothTemplateSketch.png")!,
    UIImage(named: "PhotoboothTemplateKakao.png")!,
    UIImage(named: "PhotoboothTemplateKakao2.png")!,
    UIImage(named: "PhotoboothTemplateKakao3.png")!,
    UIImage(named: "PhotoboothTemplatePhotocards.png")!,
    UIImage(named: "PhotoboothTemplatePhotocards2.png")!,
    UIImage(named: "PhotoboothTemplateKodak.png")!
]
let topImageTemplatePreview = [ // Overlay template array (for previewing)
    UIImage(named: "PhotoboothTemplateSketchPreview.png")!,
    UIImage(named: "PhotoboothTemplateKakaoPreview.png")!,
    UIImage(named: "PhotoboothTemplateKakao2.png")!,
    UIImage(named: "PhotoboothTemplateKakao3Preview.png")!,
    UIImage(named: "PhotoboothTemplatePhotocardsPreview.png")!,
    UIImage(named: "PhotoboothTemplatePhotocards2Preview.png")!,
    UIImage(named: "PhotoboothTemplateKodak.png")!
]
let areaSizes = [ // Areas to place the photos in
    areaSizeSketch,
    areaSizeKakao,
    areaSizeKakao2,
    areaSizeKakao3,
    areaSizePhotocards,
    areaSizePhotocards,
    areaSizeKodak
]
let areaSizesPreview = [
    areaSizeSketch,
    areaSizeKakaoPreview,
    areaSizeKakao2,
    areaSizeKakao3Preview,
    areaSizePhotocards,
    areaSizePhotocards,
    areaSizeKodak
]

// Structs
struct urlStruct: Codable {
    let url: [String]
}

struct pageNumberStruct: Codable {
    let contentsnumber: Int!
    let pagenumber: Int!
}

struct Message: Encodable {
    let af: Bool
}

struct responseMessage: Codable {
    let message: String!
}

struct FolderShareURLStruct: Codable {
    var path: String!
    var settings = FolderShareURLSettingsStruct()
}

struct FolderShareURLSettingsStruct: Codable {
    var access: String!
    var allow_download: Bool!
    var audience: String!
    var requested_visibility: String!
}

struct FolderShareURLResponseStruct: Codable {
    var url: String!
}

