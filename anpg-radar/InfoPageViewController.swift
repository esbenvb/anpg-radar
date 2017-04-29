//
//  InfoPageViewController.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 02/12/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import UIKit

typealias InfoPageItem = (title: String, content: NSAttributedString, action: (()->())?)

class InfoPageViewController: UITableViewController {

    lazy var aboutAnpgString: NSAttributedString = {
        let attrString = NSMutableAttributedString(string: "ANPG (short for Automatisk NummerPlade Genkendelse) is a system that registers cars and their license plates, and stores the data for a certain period. Most people are not aware of this, neither do they know where and when their car is being registered.\n\nThis app can show you where the cameras have been discovered, and warn you when getting near.\n\nBe aware that police cars may also register your license plate,. This app only warns about the cameras at fixed positions. They might look like the following.")
        let textAttachment = NSTextAttachment()
        textAttachment.image = #imageLiteral(resourceName: "anpg")
        let stringWithImage = NSAttributedString(attachment: textAttachment)
        attrString.append(stringWithImage)
        return attrString
    }()
    
    lazy var pageContent: [InfoPageItem] = {
        return [
            InfoPageItem(title: "Report new camera", content: NSAttributedString(string: "The camera list is maintained by Christian Panton from anpg.dk. Click to contact him."), action: {
                guard let url = URL(string: "https://christian.panton.org/pages/contact.html") else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }),
            InfoPageItem(title: "What is APNG?", content: self.aboutAnpgString, action: nil),
            InfoPageItem(title: "About", content: NSAttributedString(string: "This app is made by Esben von Buchwald and its main purpose is to make clear to the citizens, how often they are registered, in an attempt to bring increased attention to the problems with mass surveillance.\n\nNobody currently profits from this app."), action: {
                guard let url = URL(string: "https://www.linkedin.com/in/esbenvb/") else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }),
            InfoPageItem(title: "Data Source", content: NSAttributedString(string: "Data is provided by the anpg.dk website and is collected by users."), action: {
                guard let url = URL(string: "https://anpg.dk/?source=anpg-radar") else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }),
            InfoPageItem(title: "Privacy", content: NSAttributedString(string: "This app does not collect any sensitive information or hand it over to 3rd parties. Location is only used for showing your position on the map, distances to cameras and for enabling warnings. The application is not running/tracking location in the background, even when the warnings are enabled. Furthermore, enabling warnings should have no impact on power consumption.\n\nGoogle Analytics is used to collect anonymous usage statistics."), action: nil),
        ]
    }()
    
    let cellIdentifier = "contentCellIdentifier"
    let versionString: String = {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return "N/A"}
        return "Version \(shortVersion) build \(version) "
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 10
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "APNG Radar"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
    }
 
    func close() {
        navigationController?.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let headerCell = InfoPageHeaderTableViewCell.create()
            headerCell.versionLabel.text = versionString
            return headerCell
        }
        let item = pageContent[indexPath.section - 1]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.selectionStyle = item.action == nil ? .none : .default
        cell.accessoryType = item.action == nil ? .none : .disclosureIndicator
        cell.textLabel?.attributedText = item.content
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return pageContent.count + 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        pageContent[indexPath.section - 1].action?()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        return pageContent[section - 1].title
    }
}

