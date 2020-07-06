//
//  DrawScrambleViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 2/24/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//


import UIKit
import WebKit

// 0 = 2x2
// 1 = 3x3
// 2 = 4x4
// 3 = 5x5
// 4 = 6x6
// 5 = 7x7
// 6 = pyra
// 7 = mega
// 8 = sq1
// 9 = skewb
// 10 = clock
// 11 = BLD

let events = ["222", "333", "444", "555", "666", "777", "pyram", "minx", "sq1", "skewb", "clock", "333bf"]

class DrawScrambleViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    let jsURL = Bundle.main.url(forResource: "scramble-display.browser", withExtension: "js")
    
    override func viewDidLoad()
    {
        let source: String = """
var meta = document.createElement('meta');
meta.name = 'viewport';
meta.content = 'width=device-width, initial-scale=0.45, maximum-scale=0.45, user-scalable=no';
var head = document.getElementsByTagName('head')[0];
head.appendChild(meta);
"""
        let zoomDisableScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            
        webView.configuration.userContentController.addUserScript(zoomDisableScript)
        webView.scrollView.isScrollEnabled = false
        
        updateDrawScramble()
    }
    
    func updateDrawScramble()
    {
        let HTMLString = """
<!DOCTYPE html>
<html lang="en">
<head>
    <script src="scramble-display.browser.js"></script>
    <style type="text/css">
    <!--
    scramble-display
    {
        display: block;
        margin-left: auto;
        margin-right: auto;
    }
    -->
    </style>
</head>
<body>
    <scramble-display
        event="\(events[HomeViewController.mySession.scrambler.myEvent])"
    scramble="\(HomeViewController.mySession.getCurrentScramble())"
    ></scramble-display>
</body>
</html>
"""
        webView!.loadHTMLString(HTMLString, baseURL: jsURL?.deletingLastPathComponent())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
