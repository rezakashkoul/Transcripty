//
//  ViewController.swift
//  Transcripty
//
//  Created by Reza Kashkoul on 7/4/1400 AP.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @objc func recordActionButton(sender: UIButton!) {
        print("Record Button tapped")
        if recordButton.titleLabel?.text == "Record" {
            soundRecorder.record()
            recordButton.setTitle("Stop", for: .normal)
            playButton.isEnabled = false
            requestTranscribePermissions()
            transcribeAudio(url: getDocumentDirectory().appendingPathComponent(fileName))
        } else {
            soundRecorder.stop()
            recordButton.setTitle("Record", for: .normal)
            playButton.isEnabled = false
            requestTranscribePermissions()
            transcribeAudio(url: getDocumentDirectory().appendingPathComponent(fileName))
        }
    }
    
    @objc func playActionButton(sender: UIButton!) {
        print("Play Button tapped")
        if playButton.titleLabel?.text == "Play" {
            playButton.setTitle("Stop", for: .normal)
            recordButton.isEnabled = false
            setupPlayer()
            soundPlayer.play()
        } else {
            soundPlayer.stop()
            playButton.setTitle("Play", for: .normal)
            recordButton.isEnabled = false
        }
    }
    
    let textView = UITextView()
    let recordButton = UIButton()
    let playButton = UIButton()
    var soundRecorder : AVAudioRecorder!
    var soundPlayer : AVAudioPlayer!
    var fileName = "audioFile.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        
        setupRecorder()
        playButton.isEnabled = false
        
        createTextView()
        createPlayButton()
        createRecordButton()
    }
    
    func createRecordButton() {
        recordButton.backgroundColor = .link
        recordButton.setTitle("Record", for: .normal)
        recordButton.addTarget(self, action: #selector(recordActionButton), for: .touchUpInside)
        self.view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.layer.cornerRadius = 25
        recordButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        recordButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20).isActive = true
        //playButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        recordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
    }
    
    func createPlayButton() {
        playButton.backgroundColor = .link
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(playActionButton), for: .touchUpInside)
        self.view.addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.layer.cornerRadius = 25
        playButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20).isActive = true
        playButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        //textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
    }
    
    func createTextView() {
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.layer.cornerRadius = 25
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.gray.cgColor
        self.view.addSubview(textView)
        textView.isEditable = false
        textView.textAlignment = .left
        textView.backgroundColor = .white
        textView.text = "  Your Transcript will be shown   here!"
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        textView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        textView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 100).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -90).isActive = true
        
    }
    
    func getDocumentDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    func setupRecorder() {
        let audioFileName = getDocumentDirectory().appendingPathComponent(fileName)
        let recordSetting = [AVFormatIDKey : kAudioFormatAppleLossless , AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue , AVEncoderBitRateKey : 320000 , AVNumberOfChannelsKey : 2, AVSampleRateKey : 44100.2] as [String : Any]
        do {
            soundRecorder = try AVAudioRecorder(url: audioFileName, settings: recordSetting)
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
        } catch {
            print("error in recording process \(error)")
        }
    }
    
    func setupPlayer() {
        let audioFileName = getDocumentDirectory().appendingPathComponent(fileName)
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFileName)
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 1.0
        } catch {
            print("error in playing process \(error)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        playButton.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.isEnabled = true
        playButton.setTitle("Play", for: .normal)
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    func transcribeAudio(url: URL) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }
            if result.isFinal {
                print(result.bestTranscription.formattedString)
                textView.text = result.bestTranscription.formattedString
                textView.reloadInputViews()
            }
        }
    }
}
