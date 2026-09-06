package com.dhrishti.node.drishtisetu_node

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Bundle
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val CHANNEL = "com.dhrishti.node/audio"
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    // Real-time PCM streaming AudioTrack for Live Mic Walkie-Talkie
    private var liveAudioTrack: AudioTrack? = null
    private val SAMPLE_RATE = 16000

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        tts = TextToSpeech(this, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playAuditorVoiceAlert" -> {
                    val message = call.argument<String>("message") ?: "Auditor transmission incoming"
                    speakAuditorVoice(message)
                    playChimeTone()
                    result.success(true)
                }
                "speakMessage" -> {
                    val text = call.argument<String>("text") ?: ""
                    speakAuditorVoice(text)
                    result.success(true)
                }
                "startLiveAudioStream" -> {
                    initLiveAudioTrack()
                    result.success(true)
                }
                "writeLiveAudioChunk" -> {
                    val pcmBytes = call.argument<ByteArray>("data")
                    if (pcmBytes != null && pcmBytes.isNotEmpty()) {
                        writeLiveChunk(pcmBytes)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopLiveAudioStream" -> {
                    stopLiveAudioTrack()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale.US
            isTtsReady = true
        }
    }

    private fun setSpeakerphoneBoost() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isSpeakerphoneOn = true
    }

    private fun speakAuditorVoice(message: String) {
        setSpeakerphoneBoost()
        if (isTtsReady && tts != null) {
            tts?.speak(message, TextToSpeech.QUEUE_FLUSH, null, "AuditorTalkback")
        }
    }

    @Synchronized
    private fun initLiveAudioTrack() {
        setSpeakerphoneBoost()
        if (liveAudioTrack == null) {
            val minBufferSize = AudioTrack.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val bufferSize = Math.max(minBufferSize, 4096)

            liveAudioTrack = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()

            liveAudioTrack?.play()
        }
    }

    @Synchronized
    private fun writeLiveChunk(pcmBytes: ByteArray) {
        if (liveAudioTrack == null) {
            initLiveAudioTrack()
        }
        liveAudioTrack?.write(pcmBytes, 0, pcmBytes.size)
    }

    @Synchronized
    private fun stopLiveAudioTrack() {
        try {
            liveAudioTrack?.stop()
            liveAudioTrack?.release()
        } catch (_: Exception) {}
        liveAudioTrack = null
    }

    private fun playChimeTone() {
        Thread {
            try {
                val sampleRate = 44100
                val durationMs = 350
                val numSamples = durationMs * sampleRate / 1000
                val generatedSnd = ByteArray(2 * numSamples)

                val freqOfTone = 880.0 // A5 pleasant chime
                for (i in 0 until numSamples) {
                    val dVal = Math.sin(2.0 * Math.PI * i.toDouble() / (sampleRate / freqOfTone))
                    val dVal2 = Math.sin(2.0 * Math.PI * i.toDouble() / (sampleRate / 1174.66)) // D6 harmony
                    val sample = ((dVal + dVal2) * 0.5 * 32767).toInt().toShort()
                    generatedSnd[i * 2] = (sample.toInt() and 0x00ff).toByte()
                    generatedSnd[i * 2 + 1] = ((sample.toInt() and 0xff00) ushr 8).toByte()
                }

                val audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(generatedSnd.size)
                    .build()

                audioTrack.write(generatedSnd, 0, generatedSnd.size)
                audioTrack.play()
                Thread.sleep(durationMs.toLong() + 50)
                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()
    }

    override fun onDestroy() {
        stopLiveAudioTrack()
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
    }
}
