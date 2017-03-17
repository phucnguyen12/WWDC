//
//  ViewController.swift
//  WWDC
//
//  Created by Guilherme Rambo on 05/02/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa
import ConfCore
import RealmSwift

class ViewController: NSViewController {

    private let disposeBag = DisposeBag()
    
    private var storage: Storage!
    private lazy var client = AppleAPIClient(environment: .test)
    
    private lazy var realmConfiguration: Realm.Configuration? = {
        guard let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first else { return nil }
        let dirPath = desktop + "/RealConfCoreStorage/\(Date().timeIntervalSinceReferenceDate)/"
        
        if !FileManager.default.fileExists(atPath: dirPath) {
            do {
                try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return Realm.Configuration(fileURL: URL(fileURLWithPath: dirPath + "tests.realm"))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            storage = try Storage(realmConfiguration!)
            
            storage.schedule.observeOn(MainScheduler.instance).subscribe(onNext: { schedule in
                NSLog("Schedule = \(schedule.toArray())")
            }).addDisposableTo(self.disposeBag)
            
            client.fetchSessions { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .error(let error):
                        NSAlert(error: error).runModal()
                    case .success(let response):
                        self?.storage.store(objects: response.events)
                        self?.storage.store(objects: response.sessions)
                        self?.storage.store(objects: response.assets)
                        
                        self?.client.fetchSchedule { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .error(let error):
                                    NSAlert(error: error).runModal()
                                case .success(let response):
                                    self?.storage.store(objects: response.rooms)
                                    self?.storage.store(objects: response.tracks)
                                    self?.storage.store(objects: response.instances)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
