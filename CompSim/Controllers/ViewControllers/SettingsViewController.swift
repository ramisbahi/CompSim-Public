//
//  EventViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/4/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import MessageUI
import RealmSwift

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate
{
    @IBOutlet weak var DarkModeLabel: UILabel!
    @IBOutlet weak var DarkModeControl: UISegmentedControl!
    @IBOutlet weak var ScrollView: UIScrollView!
    
    @IBOutlet weak var solveTypeLabel: UILabel!
    @IBOutlet weak var solveTypeControl: UISegmentedControl!
    // checked for when view disappears, no point updating every time it changes
    
    @IBOutlet weak var TimingControl: UISegmentedControl!
    @IBOutlet weak var InspectionControl: UISegmentedControl!
    
    @IBOutlet weak var TabItem: UITabBarItem!
    
    @IBOutlet weak var HoldingTimeLabel: UILabel!
    @IBOutlet weak var HoldingTimeSlider: UISlider!
    
    @IBOutlet var eventCollection: [UIButton]!
    
    @IBOutlet var cuberCollection: [UIButton]!
    
    @IBOutlet var TopButtons: [UIButton]!
    
    @IBOutlet var TopLabels: [UILabel]!
    
    @IBOutlet var BigView: UIView!
    @IBOutlet weak var LittleView: UIView!
    
    @IBOutlet weak var TimerUpdateLabel: UILabel!
    
    @IBOutlet weak var CuberButton: UIButton!
    @IBOutlet weak var ScrambleTypeButton: UIButton!
    
    @IBOutlet weak var InspectionVoiceAlertsControl: UISegmentedControl!
    @IBOutlet weak var TimerUpdateControl: UISegmentedControl!
    
    @IBOutlet weak var VersionLabel: UILabel!
    
    @IBOutlet weak var WebsiteButton: UIButton!
    
    @IBOutlet weak var EmailButton: UIButton!
    
    @IBOutlet var ControlCollection: [UISegmentedControl]!
    
    var cuberDictionary = ["Bill" : "Bill Wang", "Lucas" : "Lucas Etter", "Feliks" : "Feliks Zemdegs", "Kian" : "Kian Mansour", "Random" : NSLocalizedString("Random", comment: ""), "Rami" : "Rami Sbahi", "Patrick" : "Patrick Ponce", "Max" : "Max Park", "Kevin" : "Kevin Hays"]
    
    let realm = try! Realm()
    
    @IBAction func DarkModeChanged(_ sender: Any) {
        HomeViewController.changedDarkMode = true
        StatsViewController.changedDarkMode = true
        if(!HomeViewController.darkMode) // not dark, set to dark
        {
            HomeViewController.darkMode = true
            makeDarkMode()
        }
        else // dark, turn off
        {
            HomeViewController.darkMode = false
            turnOffDarkMode()
        }
    }
    
    @IBAction func TimingChanged(_ sender: Any) {
        
        HomeViewController.timing = TimingControl.selectedSegmentIndex
        
        if(HomeViewController.timing == 1) // off
        {
            InspectionControl.isEnabled = false
            InspectionVoiceAlertsControl.isEnabled = false
        }
        else // on
        {
            InspectionControl.isEnabled = true
            if(HomeViewController.inspection)
            {
                InspectionVoiceAlertsControl.isEnabled = true
            }
        }
    }
    
    
    @IBAction func WebsiteButtonTouched(_ sender: Any) {
        guard let url = URL(string: "http://www.compsim.net") else {
          return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func EmailButtonTouched(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["compsimcubing@gmail.com"])
            mail.setSubject("CompSim Inquiry")
            mail.setMessageBody("<p>Dear CompSim,</p>", isHTML: true)

            present(mail, animated: true)
        } else {
            print("fail")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @IBAction func InspectionChanged(_ sender: Any) {
        if(HomeViewController.inspection)
        {
            HomeViewController.inspection = false
            InspectionVoiceAlertsControl.isEnabled = false
        }
        else
        {
            HomeViewController.inspection = true
            InspectionVoiceAlertsControl.isEnabled = true
        }
    }
    
    @IBAction func InspectionVoiceAlertsChanged(_ sender: Any) {
        HomeViewController.inspectionSound = !HomeViewController.inspectionSound
    }
    
    func makeDarkMode()
    {
        BigView.backgroundColor = HomeViewController.darkModeColor()
        LittleView.backgroundColor = HomeViewController.darkModeColor()
        ScrollView.backgroundColor = HomeViewController.darkModeColor()
        let allButtons = TopButtons + cuberCollection + eventCollection
        allButtons.forEach{ (button) in
        
            button.backgroundColor = HomeViewController.darkPurpleColor()
        }
        
        TopLabels.forEach{ (label) in
        
            label.textColor = .white
        }
        
        let controlSize: CGFloat = NSLocale.preferredLanguages[0].contains("es-") ? 10.0 : 14.0
    
    
        ControlCollection.forEach{(control) in
            control.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
            control.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Lato-Black", size: controlSize)!, NSAttributedString.Key.foregroundColor: HomeViewController.darkModeColor()], for: .normal)
        }
        
        HoldingTimeSlider.thumbTintColor = HomeViewController.orangeColor()
        
        EmailButton.backgroundColor = .white
        EmailButton.setTitleColor(HomeViewController.darkModeColor(), for: .normal)
        EmailButton.imageView?.tintColor = HomeViewController.darkModeColor()
        WebsiteButton.backgroundColor = .white
        WebsiteButton.setTitleColor(HomeViewController.darkModeColor(), for: .normal)
        WebsiteButton.imageView?.tintColor = HomeViewController.darkModeColor()
    
        VersionLabel.textColor = .white
        
        self.tabBarController?.tabBar.barTintColor = HomeViewController.darkPurpleColor()
        
        setNeedsStatusBarAppearanceUpdate()
        updateStatusBarBackground()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        updateStatusBarBackground()
    }
    
    func updateStatusBarBackground()
    {
        if #available(iOS 13.0, *) {
            let statusBar = UIView(frame: view.window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
            statusBar.backgroundColor = HomeViewController.darkMode ?  HomeViewController.darkModeColor() : .white
             view.addSubview(statusBar)
        }
    }
    
    func turnOffDarkMode()
    {
        BigView.backgroundColor = .white
        LittleView.backgroundColor = .white
        ScrollView.backgroundColor = .white
        
        let allButtons = TopButtons + cuberCollection + eventCollection
        allButtons.forEach{ (button) in
        
            button.backgroundColor = HomeViewController.darkBlueColor()
        }
        
        TopLabels.forEach{ (label) in
        
            label.textColor = HomeViewController.darkBlueColor()
        }
        
        let controlSize: CGFloat = NSLocale.preferredLanguages[0].contains("es-") ? 10.0 : 14.0
        
        ControlCollection.forEach{(control) in
            control.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
            control.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Lato-Black", size: controlSize)!, NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        }
        
        HoldingTimeSlider.thumbTintColor = HomeViewController.darkBlueColor()
        
        EmailButton.backgroundColor = HomeViewController.darkBlueColor()
        EmailButton.setTitleColor(.white, for: .normal)
        EmailButton.imageView?.tintColor = .white
        WebsiteButton.backgroundColor = HomeViewController.darkBlueColor()
        WebsiteButton.setTitleColor(.white, for: .normal)
        WebsiteButton.imageView?.tintColor = .white
        
        self.tabBarController?.tabBar.barTintColor = HomeViewController.darkBlueColor()
        
        VersionLabel.textColor = HomeViewController.darkBlueColor()
        setNeedsStatusBarAppearanceUpdate()
        updateStatusBarBackground()
    }
    
    
    
    @IBAction func handleSelection(_ sender: UIButton) // select
    {
        if #available(iOS 13.0, *) {
            ScrambleTypeButton.setImage(UIImage(systemName: eventCollection[0].isHidden ? "chevron.down" : "chevron.right"), for: .normal)
        }
        
        eventCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func handleCuberSelection(_ sender: Any) {
        if #available(iOS 13.0, *) {
            CuberButton.setImage(UIImage(systemName: cuberCollection[0].isHidden ? "chevron.down" : "chevron.right"), for: .normal)
        }
        cuberCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        ScrambleTypeButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: LittleView.frame.size.width - 53, bottom: 0, right: 0)
        CuberButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: LittleView.frame.size.width - 53, bottom: 0, right: 0)
        
        
    }
    
    override func viewDidLoad() // only need to do these things when lose instance anyways, so call in view did load (selected index wont change when go between tabs)
    {
        
        super.viewDidLoad()
        
        EmailButton.titleLabel?.adjustsFontSizeToFitWidth = true
        EmailButton.titleLabel?.baselineAdjustment = .alignCenters
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        
        cuberDictionary["Aleatorio"] = NSLocalizedString("Random", comment: "") // need to go through each
        if(cuberDictionary[NSLocalizedString("Random", comment: "")] == nil)
        {
            cuberDictionary[NSLocalizedString("Random", comment: "")] = NSLocalizedString("Random", comment: "")
        }
        
    
        
        if(HomeViewController.darkMode)
        {
            DarkModeControl.selectedSegmentIndex = 0
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
        
        TimingControl.selectedSegmentIndex = HomeViewController.timing
        if(HomeViewController.timing == 1)
        {
            InspectionControl.isEnabled = false
        }
        
        if(HomeViewController.timing == 1 || !HomeViewController.inspection)
        {
            InspectionVoiceAlertsControl.isEnabled = false
        }
        
        if(HomeViewController.inspection)
        {
            InspectionControl.selectedSegmentIndex = 0
        }
        else
        {
            InspectionControl.selectedSegmentIndex = 1
        }
        
        if(HomeViewController.inspectionSound)
        {
            InspectionVoiceAlertsControl.selectedSegmentIndex = 0
        }
        else
        {
            InspectionVoiceAlertsControl.selectedSegmentIndex = 1
        }
        
        
        if(HomeViewController.cuber == "Malik")
        {
            HomeViewController.cuber = "Rami"
        }
        
        let title = cuberDictionary[HomeViewController.cuber]!
        let cuber = NSLocalizedString("Cuber", comment: "")
        let cuberString = NSMutableAttributedString(string: "\(cuber):  \(title)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        cuberString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: cuber.count + 1, length: cuberString.length - cuber.count - 1))
        CuberButton.setAttributedTitle(cuberString, for: .normal)
        
        cuberCollection.forEach({ button in
            if button.titleLabel?.text == cuberDictionary[HomeViewController.cuber]
            {
                button.setTitleColor(HomeViewController.orangeColor(), for: .normal)
            }
        })
    
        HoldingTimeSlider.value = HomeViewController.holdingTime
        let holdingTime = NSLocalizedString("Holding Time", comment: "")
        HoldingTimeLabel.text = String(format: "\(holdingTime): %.2f", HomeViewController.holdingTime)
        
        TimerUpdateControl.selectedSegmentIndex = HomeViewController.timerUpdate
        
        WebsiteButton.setTitle(NSLocalizedString("Website", comment: ""), for: .normal)
        EmailButton.setTitle(NSLocalizedString("Email", comment: ""), for: .normal)
        VersionLabel.text = NSLocalizedString("Version", comment: "") + ": \(appVersion)"
        
        var font = HomeViewController.fontToFitHeight(view: ScrambleTypeButton, multiplier: 0.3, name: "Lato-Black")
        let widthFont = HomeViewController.fontToFitWidth(text: "Scramble Type: 3x3x3 BLD", view: self.view, multiplier: 0.5, name: "Lato-Black")
        if widthFont.pointSize < font.pointSize
        {
            font = widthFont
        }
        ScrambleTypeButton.titleLabel?.font = font
        for button in eventCollection
        {
            button.titleLabel?.font = font
        }
        CuberButton.titleLabel?.font = font
        for button in cuberCollection
        {
            button.titleLabel?.font = font
        }
        
        
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let eventNames = ["2x2x2", "3x3x3", "4x4x4", "5x5x5", "6x6x6", "7x7x7", "Pyraminx", "Megaminx", "Square-1", "Skewb", "Clock", "3x3x3 BLD"]
        let title = eventNames[HomeViewController.mySession.scrambler.myEvent]
        let scrType = NSLocalizedString("Scramble Type", comment: "")
        let scrString = NSMutableAttributedString(string: "\(scrType):  \(title)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        scrString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: scrType.count + 1, length: scrString.length - scrType.count - 1))
        ScrambleTypeButton.setAttributedTitle(scrString, for: .normal)
        
        
        super.viewWillAppear(false)
        
        
        eventCollection.forEach { (button) in
            button.isHidden = true
            if button.titleLabel?.text == title
            {
                button.setTitleColor(HomeViewController.orangeColor(), for: .normal)
            }
            else
            {
                button.setTitleColor(.white, for: .normal)
            }
        }
        
        
        solveTypeControl.isEnabled = HomeViewController.mySession.currentIndex < 1
        solveTypeControl.selectedSegmentIndex = HomeViewController.mySession.solveType
        
        if #available(iOS 13.0, *) {
            CuberButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
            ScrambleTypeButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        }
    }
    
    @IBAction func HoldingTimeChanged(_ sender: Any) {
        
        let roundedTime = round(HoldingTimeSlider.value * 20) / 20 // 0.29 --> 0.3, 0.27 --> 0.25
        let holdingTime = NSLocalizedString("Holding Time", comment: "")
        HoldingTimeLabel.text = String(format: "\(holdingTime): %.2f", roundedTime)
        HomeViewController.holdingTime = roundedTime
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(false)
        
        try! realm.write {
            HomeViewController.mySession.solveType = solveTypeControl.selectedSegmentIndex
        }
        
        HomeViewController.timerUpdate = TimerUpdateControl.selectedSegmentIndex

    }
    
    enum Events: String
    {
        case twoCube = "2x2x2"
        case threeCube = "3x3x3"
        case fourCube = "4x4x4"
        case fiveCube = "5x5x5"
        case sixCube = "6x6x6"
        case sevenCube = "7x7x7"
        case pyra = "Pyraminx"
        case mega = "Megaminx"
        case sq1 = "Square-1"
        case skewb = "Skewb"
        case clock = "Clock"
        case BLD = "3x3x3 BLD"
    }
    
    
    @IBAction func cuberTapped(_ sender: UIButton) {
        
        if #available(iOS 13.0, *) {
            CuberButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        }
        
        
        cuberCollection.forEach { (button) in
            button.setTitleColor(.white, for: .normal)
        }
        
        sender.setTitleColor(HomeViewController.orangeColor(), for: .normal)
        
        cuberCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle else
        {
            return // doesn't have title
        }
        
        let cuber = NSLocalizedString("Cuber", comment: "")
        let cuberString = NSMutableAttributedString(string: "\(cuber):  \(title)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        cuberString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: cuber.count + 1, length: cuberString.length - cuber.count - 1))
        CuberButton.setAttributedTitle(cuberString, for: .normal)
        
        let nameArr = title.components(separatedBy: " ")
        HomeViewController.cuber = nameArr[0]
    }
    
    
    @IBAction func eventTapped(_ sender: UIButton) {
        
        if #available(iOS 13.0, *) {
            ScrambleTypeButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        }
        
        
        eventCollection.forEach { (button) in
            button.setTitleColor(.white, for: .normal)
        }
        
        sender.setTitleColor(HomeViewController.orangeColor(), for: .normal)
        
        eventCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle, let event = Events(rawValue: title) else
        {
            return // doesn't have title
        }
        
        let scrType = NSLocalizedString("Scramble Type", comment: "")
        let scrString = NSMutableAttributedString(string: "\(scrType):  \(title)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        scrString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: scrType.count + 1, length: scrString.length - scrType.count - 1))
        ScrambleTypeButton.setAttributedTitle(scrString, for: .normal)
        
        try! realm.write
        {
            switch event
            {
                case .twoCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 0)
                case .threeCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 1)
                case .fourCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 2)
                case .fiveCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 3)
                case .sixCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 4)
                case .sevenCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 5)
                case .pyra:
                    HomeViewController.mySession.doEvent(enteredEvent: 6)
                case .mega:
                    HomeViewController.mySession.doEvent(enteredEvent: 7)
                case .sq1:
                    HomeViewController.mySession.doEvent(enteredEvent: 8)
                case .skewb:
                    HomeViewController.mySession.doEvent(enteredEvent: 9)
                case .clock:
                    HomeViewController.mySession.doEvent(enteredEvent: 10)
                case .BLD:
                    HomeViewController.mySession.doEvent(enteredEvent: 11)
            }
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if #available(iOS 13.0, *)
        {
            if HomeViewController.darkMode
            {
                return .lightContent
            }
            
        }
        
        return .default
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
