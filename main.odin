package osyn

import "core:c"
import "core:fmt"
import "core:log"
import "core:os"

import ma "vendor:miniaudio"
import rl "vendor:raylib"

// Procdef Generic

read_input :: proc() -> string {
	buf: [256]byte
	num_bytes, err := os.read(os.stdin, buf[:])

	// TODO: handle error
	str := string(buf[:num_bytes - 1])

	return str
}

// Procdef MiniAudio

data_callback :: proc "c" (pDevice: ^ma.device, pOutput: rawptr, pInput: rawptr, frameCount: u32) {
	pSineWave := cast(^ma.waveform)pDevice.pUserData
	ma.waveform_read_pcm_frames(pSineWave, pOutput, cast(u64)frameCount, nil)
}

init_ma_device_data :: proc() -> (ma.device_config, ma.device) {
	device: ma.device

	deviceConfig := ma.device_config_init(ma.device_type.playback)
	deviceConfig.playback.format = ma.format.f32
	deviceConfig.playback.channels = 2
	deviceConfig.sampleRate = 48000

	deviceConfig.dataCallback = data_callback

	return deviceConfig, device
}

// Main

main :: proc() {
	sineWave: ma.waveform

	// Init Logging
	logger := log.create_console_logger()
	context.logger = logger

	deviceConfig, device := init_ma_device_data()
	deviceConfig.pUserData = &sineWave

	if ma.device_init(nil, &deviceConfig, &device) != ma.result.SUCCESS {
		os.exit(-1)
	}

	// Setup Waveform
	log.infof("Device Name: %s\n", device.playback.name)
	sineWaveConfig := ma.waveform_config_init(
		device.playback.playback_format,
		device.playback.channels,
		device.sampleRate,
		ma.waveform_type.sine,
		0.2,
		220,
	)
	ma.waveform_init(&sineWaveConfig, &sineWave)

	// Load Device
	ma.device_start(&device)

	// Wait
	fmt.println("Press Enter to quit...")
	_ = read_input()

	// Unload Device & Destroy Logger
	ma.device_uninit(&device)
	log.destroy_console_logger(logger)
}

