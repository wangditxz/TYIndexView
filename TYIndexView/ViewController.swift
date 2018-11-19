//
//  ViewController.swift
//  TYIndexView
//
//  Created by 王迪 on 2018/11/19.
//  Copyright © 2018年 王迪. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var dataArray, titleArray, indexArray: [String]!;
    override func viewDidLoad() {
        super.viewDidLoad()
        var dataArray: [String] = [];
        var titleArray: [String] = [];
        var indexArray: [String] = [];
        for i in 0...20 {
            dataArray.append("我是第\(i + 1)个 section 里的数据");
            titleArray.append("第\(i + 1)区");
            indexArray.append("\(i + 1)");
        }
        self.dataArray = dataArray;
        self.titleArray = titleArray;
        self.indexArray = indexArray;
        
        let tableView = UITableView(frame: self.view.bounds, style: .grouped);
        tableView.delegate = self;
        tableView.dataSource = self;
        self.view.addSubview(tableView);
        
        let indexView = TYIndexView(frame: self.view.bounds, tableView: tableView, config: TYIndexViewConfiguration());
        indexView.dataSource = self.indexArray;
        view.addSubview(indexView);
    }

    // MARK: - tableView delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell");
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell");
        }
        cell?.textLabel?.text = dataArray[indexPath.section];
        cell?.textLabel?.textColor = UIColor.red;
        return cell!;
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleArray[section];
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("clickCell");
    }

}

