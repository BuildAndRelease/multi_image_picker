import AVFoundation
import UIKit

public enum VideoQuality {
    case very_high
    case high
    case medium
    case low
    case very_low
}

// Compression Result
public enum CompressionResult {
    case onStart
    case onSuccess(URL, CGSize)
    case onFailure(CompressionError)
    case onCancelled
}

// Compression Interruption Wrapper
public class Compression {
    public init() {}
    
    public var cancel = false
}

// Compression Error Messages
public struct CompressionError: LocalizedError {
    public let title: String
    
    init(title: String = "Compression Error") {
        self.title = title
    }
}

//@available(iOS 11.0, *)
public struct LightCompressor {
    
    public init() {}
    
    private let MIN_BITRATE = Float(2000000)
    private let MIN_HEIGHT = 640.0
    private let MIN_WIDTH = 360.0
    
    /**
     * This function compresses a given [source] video file and writes the compressed video file at
     * [destination]
     *
     * @param [source] the path of the provided video file to be compressed
     * @param [destination] the path where the output compressed video file should be saved
     * @param [quality] to allow choosing a video quality that can be [.very_low], [.low],
     * [.medium],  [.high], and [very_high]. This defaults to [.medium]
     * @param [isMinBitRateEnabled] to determine if the checking for a minimum bitrate threshold
     * before compression is enabled or not. This default to `true`
     * @param [keepOriginalResolution] to keep the original video height and width when compressing.
     * This defaults to `false`
     * @param [progressHandler] a compression progress  listener that listens to compression progress status
     * @param [completion] to return completion status that can be [onStart], [onSuccess], [onFailure],
     * and if the compression was [onCancelled]
     */
    public func compressVideo(source: AVAsset,
                              destination: URL,
                              quality: VideoQuality,
                              keepOriginalResolution: Bool = false,
                              completion: @escaping (CompressionResult) -> ()) -> Compression {
        
        let compressionOperation = Compression()
        completion(.onStart)
        
        guard let videoTrack = source.tracks(withMediaType: AVMediaType.video).first else {
            let error = CompressionError(title: "Cannot find video track")
            completion(.onFailure(error))
            return Compression()
        }
        
        let audioTrack = source.tracks(withMediaType: AVMediaType.audio).first
        
        // Generate a bitrate based on desired quality
        let bitrate = videoTrack.estimatedDataRate
        let newBitrate = getBitrate(bitrate: bitrate, quality: quality)
        
        // Handle new width and height values
        let videoSize = videoTrack.naturalSize
        let size = generateWidthAndHeight(width: videoSize.width, height: videoSize.height, keepOriginalResolution: keepOriginalResolution)
        let newWidth = size.width
        let newHeight = size.height
        
        guard let assetReader = try? AVAssetReader(asset: source),let assetWriter = try? AVAssetWriter(outputURL: destination, fileType: AVFileType.mov) else {
            let error = CompressionError(title: "The assetWriter init failed")
            completion(.onFailure(error))
            return Compression()
        }
        
        // Setup video writer input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: videoTrack.mediaType, outputSettings: getVideoWriterSettings(bitrate: newBitrate, width: newWidth, height: newHeight))
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = videoTrack.preferredTransform
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        // Setup video reader output
        let videoReaderSettings:[String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
        ]
        let readerVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        readerVideoOutput.alwaysCopiesSampleData = false
        if assetReader.canAdd(readerVideoOutput) {
            assetReader.add(readerVideoOutput)
        }
        
        // 兼容某些视频没有音轨
        var assetWriterAudioInput : AVAssetWriterInput?
        var readerAudioOutput : AVAssetReaderTrackOutput?
        if audioTrack != nil {
            // Setup audio reader output
            let decompressionAudioSettings: [String : AnyObject] = [
                AVFormatIDKey: kAudioFormatLinearPCM as AnyObject,
            ]
            readerAudioOutput = AVAssetReaderTrackOutput(track: audioTrack!, outputSettings: decompressionAudioSettings)
            assetReader.add(readerAudioOutput!)
            // Setup audio writer input
            assetWriterAudioInput = AVAssetWriterInput(mediaType: audioTrack!.mediaType, outputSettings: getAudioWriterSettings())
            assetWriter.add(assetWriterAudioInput!)
        }
        
        //start writing from video reader
        guard assetReader.startReading(), assetWriter.startWriting() else {
            let error = CompressionError(title: "The assetReader startReading assetWriter startWriting failed")
            completion(.onFailure(error))
            return Compression()
        }
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        var videoComplete = false
        // 兼容某些视频没有音轨
        var audioComplete = audioTrack == nil
        
        let finishBlock = {
            assetWriter.finishWriting {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: {
                    completion(.onSuccess(destination, CGSize(width: newWidth, height: newHeight)))
                })
            }
        }
        
        assetWriterVideoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "videoOutQueue")) {
            while (assetWriterVideoInput.isReadyForMoreMediaData && assetReader.status == .reading) {
                guard let sampleBuffer = readerVideoOutput.copyNextSampleBuffer() else {
                    assetWriterVideoInput.markAsFinished()
                    videoComplete = true
                    if audioComplete {
                        finishBlock()
                    }
                    return
                }
                assetWriterVideoInput.append(sampleBuffer)
            }
        }
        
        // 兼容某些视频没有音轨
        if let assetWriterAudioInput = assetWriterAudioInput, let readerAudioOutput = readerAudioOutput {
            assetWriterAudioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "voiceOutQueue")) {
                while (assetWriterAudioInput.isReadyForMoreMediaData && assetReader.status == .reading) {
                    guard let sampleBuffer = readerAudioOutput.copyNextSampleBuffer() else {
                        assetWriterAudioInput.markAsFinished()
                        audioComplete = true
                        if videoComplete {
                            finishBlock()
                        }
                        return
                    }
                    assetWriterAudioInput.append(sampleBuffer)
                }
            }
        }
        
        return compressionOperation
    }
    
    private func getBitrate(bitrate: Float, quality: VideoQuality) -> Int {
        if bitrate < MIN_BITRATE {
            return Int(bitrate);
        }
        if quality == .very_low {
            return Int(bitrate * 0.08)
        } else if quality == .low {
            return Int(bitrate * 0.1)
        } else if quality == .medium {
            return Int(bitrate * 0.2)
        } else if quality == .high {
            return Int(bitrate * 0.3)
        } else if quality == .very_high {
            return Int(bitrate * 0.5)
        } else {
            return Int(bitrate * 0.2)
        }
    }
    
    private func generateWidthAndHeight(
        width: CGFloat,
        height: CGFloat,
        keepOriginalResolution: Bool
    ) -> (width: Int, height: Int) {
        
        if (keepOriginalResolution) {
            return (Int(width), Int(height))
        }
        
        var newWidth: Int
        var newHeight: Int
        if width >= 1920 || height >= 1920 {
            newWidth = Int(width * 0.5 / 16) * 16
            newHeight = Int(height * 0.5 / 16 ) * 16
        } else if width >= 1280 || height >= 1280 {
            newWidth = Int(width * 0.75 / 16) * 16
            newHeight = Int(height * 0.75 / 16) * 16
        } else if width >= 960 || height >= 960 {
            newWidth = Int(width * 0.85 / 16) * 16
            newHeight = Int(height * 0.85 / 16) * 16
        } else {
            newWidth = Int(width * 0.9 / 16) * 16
            newHeight = Int(height * 0.9 / 16) * 16
        }
        
        return (newWidth, newHeight)
    }
    
    private func getVideoWriterSettings(bitrate: Int, width: Int, height: Int) -> [String : AnyObject] {
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey : bitrate
        ]
        
        let videoWriterSettings: [String : AnyObject] = [
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
            AVVideoCompressionPropertiesKey : videoWriterCompressionSettings as AnyObject,
            AVVideoWidthKey : width as AnyObject,
            AVVideoHeightKey : height as AnyObject
        ]
        
        return videoWriterSettings
    }
    
    private func getAudioWriterSettings() -> [String : Any] {
        var stereoChannelLayout = AudioChannelLayout()
        stereoChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        stereoChannelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
        stereoChannelLayout.mNumberChannelDescriptions = 0
        let channelLayoutAsData = NSData(bytes: &stereoChannelLayout, length: MemoryLayout.size(ofValue: stereoChannelLayout))
        let compressionAudioSettings : [String : Any] = [
             AVFormatIDKey         : kAudioFormatMPEG4AAC,
             AVEncoderBitRateKey   : 128000,
             AVSampleRateKey       : 44100,
             AVChannelLayoutKey    : channelLayoutAsData,
             AVNumberOfChannelsKey : 2
        ]
        
        return compressionAudioSettings
    }
    
}
