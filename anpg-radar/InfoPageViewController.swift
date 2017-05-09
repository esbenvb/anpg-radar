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
        let attrString = NSMutableAttributedString(string: "label.info.whatisanpg".localized)
        let textAttachment = NSTextAttachment()
        textAttachment.image = #imageLiteral(resourceName: "anpg")
        let stringWithImage = NSAttributedString(attachment: textAttachment)
        attrString.append(stringWithImage)
        return attrString
    }()
    
    lazy var pageContent: [InfoPageItem] = {
        return [
            InfoPageItem(title: "title.info.reportcamera".localized, content: NSAttributedString(string: "label.info.reportcamera".localized), action: {
                guard let url = URL(string: "https://christian.panton.org/pages/contact.html") else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }),
            InfoPageItem(title: "title.info.whatisanpg".localized, content: self.aboutAnpgString, action: nil),
            InfoPageItem(title: "title.info.about".localized, content: NSAttributedString(string: "label.info.about".localized), action: {
                guard let url = URL(string: "https://www.linkedin.com/in/esbenvb/") else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }),
            InfoPageItem(title: "title.info.datasource".localized, content: NSAttributedString(string: "label.info.datasource".localized), action: {
                guard let url = URL(string: "https://anpg.dk/?source=anpg-radar") else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }),
            InfoPageItem(title: "title.info.privacy".localized, content: NSAttributedString(string: "label.info.privacy".localized), action: nil),
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
        navigationItem.title = "app.title".localized
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

