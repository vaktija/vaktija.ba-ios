//
//  RingtonesTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import AVFoundation

class RingtonesTableViewController: UITableViewController
{
    enum RintoneType: String
    {
        case Alarm = "alarm"
        case Notification = "notification"
    }
    
    var ringtoneType: RintoneType = .Alarm
    fileprivate var ringtones: [String] = []
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var fileName = String()
    fileprivate var thereAreChanges = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        if ringtoneType == .Notification
        {
			navigationItem.title = "Zvukovi za notifikacije"
        }
        else
        {
			navigationItem.title = "Zvukovi za alarm"
        }
        
        do
        {
            ringtones = try FileManager().contentsOfDirectory(atPath: Bundle.main.resourcePath!)
            
            ringtones = ringtones.filter({$0.contains(ringtoneType.rawValue + ".mp3")})
        }
        catch
        {
            print(error)
        }
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        fileName = userDefaults!.string(forKey: ringtoneType.rawValue + "Ringtone")!
		
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if let goodAudioPlayer = audioPlayer
        {
            if goodAudioPlayer.isPlaying
            {
                goodAudioPlayer.stop()
            }
        }
        
        if isMovingFromParent && thereAreChanges
        {
            var shouldReschedule = false
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            let currentFileName = userDefaults!.string(forKey: ringtoneType.rawValue + "Ringtone")! 
            if currentFileName != fileName
            {
                shouldReschedule = true
            }
            
            if shouldReschedule
            {
                VBNotification().scheduleLocalNotifications(false)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return ringtones.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RingtoneCell", for: indexPath)

        // Configure the cell...
        
        let ringtoneName = ringtones[indexPath.row].components(separatedBy: ".").first
		cell.backgroundColor = UIColor.backgroundColor
        cell.textLabel?.text = ringtoneName?.components(separatedBy: "_").first
		cell.textLabel?.textColor = UIColor.titleColor
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let settingRingtoneName = userDefaults!.string(forKey: ringtoneType.rawValue + "Ringtone")!
        
        if ringtoneName!.contains(settingRingtoneName)
        {
            cell.accessoryType = .checkmark
        }
        else
        {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let ringtoneFileName = ringtones[indexPath.row].components(separatedBy: ".").first
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf:Bundle.main.url(forResource: ringtoneFileName, withExtension: "mp3")!)
            audioPlayer?.play()
        }
        catch
        {
            print(error)
        }
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        userDefaults!.set(ringtoneFileName, forKey: ringtoneType.rawValue + "Ringtone")
        thereAreChanges = true
        
        tableView.reloadData()
    }
}
