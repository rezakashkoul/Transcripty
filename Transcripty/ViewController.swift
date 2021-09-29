//
//  ViewController.swift
//  Transcripty
//
//  Created by Reza Kashkoul on 7/4/1400 AP.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate {
    
    @objc func recordActionButton(sender: UIButton!) {
        print("Record Button tapped")
        
        //        if audioEngine.isRunning {
        //            audioEngine.stop()
        //            recognitionRequest?.endAudio()
        //            recordButton.isEnabled = false
        //            recordButton.setTitle("Stopping", for: .disabled)
        //        } else {
        //            do {
        //                try startRecording()
        //                recordButton.setTitle("Stop Recording", for: [])
        //            } catch {
        //                recordButton.setTitle("Recording Not Available", for: [])
        //            }
        //        }
        
        if recordButton.titleLabel?.text == "Record" {
            soundRecorder.record()
            recordButton.setTitle("Stop", for: .normal)
            playButton.isEnabled = false
            
            do {
                try startRecording()
                recordButton.setTitle("Stop Recording", for: [])
            } catch {
                recordButton.setTitle("Recording Not Available", for: [])
            }
            
            //            requestTranscribePermissions()
            //            transcribeAudio(url: getDocumentDirectory().appendingPathComponent(fileName))
        } else {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            soundRecorder.stop()
            recordButton.setTitle("Record", for: .normal)
            playButton.isEnabled = false
            //            requestTranscribePermissions()
            //            transcribeAudio(url: getDocumentDirectory().appendingPathComponent(fileName))
        }
    }
    
    @objc func playActionButton(sender: UIButton!) {
        print("Play Button tapped")
        if playButton.titleLabel?.text == "Play" {
            playButton.setTitle("Stop", for: .normal)
            //            recordButton.isEnabled = false
            setupPlayer()
            soundPlayer.play()
        } else {
            soundPlayer.stop()
            playButton.setTitle("Play", for: .normal)
            //            recordButton.isEnabled = false
        }
    }
    let label = UILabel()
    let textView = UITextView()
    let recordButton = UIButton()
    let playButton = UIButton()
    var soundRecorder : AVAudioRecorder!
    var soundPlayer : AVAudioPlayer!
    var fileName = "audioFile.m4a"
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        self.view.addSubview(label)
        self.view.addSubview(textView)
        self.view.addSubview(recordButton)
        self.view.addSubview(playButton)
        
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
        
        setupRecorder()
        playButton.isEnabled = false
        createLabel()
        createTextView()
        createPlayButton()
        createRecordButton()
    }
    
    
    
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    
                default:
                    self.recordButton.isEnabled = false
                }
            }
        }
    }
    
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [self] result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                guard let text = self.textView.text else { return }
                
                textView.attributedText = generateAttributedString(with: String(text.split(separator: " ").last ?? ""), targetString: text)
                //textView.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 30), range: NSRange(location: 0, length:attrString.length))
                print("Your text is \(result.bestTranscription.formattedString)")
            }
            
            
            
            
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("Start Recording", for: [])
            }
        }
        
        
        
        func generateAttributedString(with searchTerm: String, targetString: String) -> NSAttributedString? {
                let attributedString = NSMutableAttributedString(string: targetString)
                do {
                    let regex = try NSRegularExpression(pattern: searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current), options: .caseInsensitive)
                    let range = NSRange(location: 0, length: targetString.utf16.count)
                    for match in regex.matches(in: targetString.folding(options: .diacriticInsensitive, locale: .current), options: .withTransparentBounds, range: range) {
                    attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.lightGray, range: match.range)
                    }
                    attributedString.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20) ], range: NSRange(location: 0, length: targetString.utf16.count))

                    return attributedString
                } catch {
                    NSLog("Error creating regular expresion: \(error)")
                    return nil
                }
            }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        textView.text = "(Go ahead, I'm listening)"
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition Not Available", for: .disabled)
        }
    }
    
    
    
    
    
    
    
    func createRecordButton() {
        recordButton.backgroundColor = .link
        recordButton.setTitle("Record", for: .normal)
        recordButton.addTarget(self, action: #selector(recordActionButton), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.layer.cornerRadius = 25
        recordButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        recordButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 250).isActive = true
        // recordButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: 30).isActive = true
        recordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60).isActive = true
        
    }
    
    
    func createPlayButton() {
        playButton.backgroundColor = .link
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(playActionButton), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.layer.cornerRadius = 25
        playButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 250).isActive = true
        playButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        //playButton.leadingAnchor.constraint(equalTo: recordButton.trailingAnchor, constant: 30).isActive = true
        playButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60).isActive = true
    }
    
    
    
    
    
    func createLabel() {
        
        
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "1. Record 2. View transcribed text 3. Play back audio with text highlighting."
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 140).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        //   label.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: 10).isActive = true
        
    }
    
    
    func createTextView() {
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        //textView.layer.cornerRadius = 25
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.textAlignment = .left
        textView.backgroundColor = .white
        textView.text = " Your Transcript will be shown here! "
        //        textView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //        textView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // textView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 20).isActive = true
        
        textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        
        textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        textView.bottomAnchor.constraint(equalTo: playButton.topAnchor, constant: -250).isActive = true
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
    
    //    func requestTranscribePermissions() {
    //        SFSpeechRecognizer.requestAuthorization { authStatus in
    //            DispatchQueue.main.async {
    //                if authStatus == .authorized {
    //                    print("Good to go!")
    //                } else {
    //                    print("Transcription permission was declined.")
    //                }
    //            }
    //        }
    //    }
    //
    //    func transcribeAudio(url: URL) {
    //        let recognizer = SFSpeechRecognizer()
    //        let request = SFSpeechURLRecognitionRequest(url: url)
    //        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
    //            guard let result = result else {
    //                print("There was an error: \(error!)")
    //                return
    //            }
    //            if result.isFinal {
    //                print(result.bestTranscription.formattedString)
    //                textView.text = result.bestTranscription.formattedString
    //                textView.reloadInputViews()
    //            }
    //        }
    //    }
}
