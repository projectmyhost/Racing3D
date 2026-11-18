function Write-WavFile {
    param (
        [string]$Path,
        [float[]]$Samples,
        [int]$SampleRate = 44100
    )
    $numSamples = $Samples.Length
    $numChannels = 1
    $bitsPerSample = 16
    $byteRate = $SampleRate * $numChannels * ($bitsPerSample / 8)
    $blockAlign = $numChannels * ($bitsPerSample / 8)
    $subChunk2Size = $numSamples * $numChannels * ($bitsPerSample / 8)
    $chunkSize = 36 + $subChunk2Size

    $stream = [System.IO.File]::Create($Path)
    $writer = New-Object System.IO.BinaryWriter($stream)

    # RIFF header
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $writer.Write([int32]$chunkSize)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))

    # fmt subchunk
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $writer.Write([int32]16)
    $writer.Write([int16]1) # PCM
    $writer.Write([int16]$numChannels)
    $writer.Write([int32]$SampleRate)
    $writer.Write([int32]$byteRate)
    $writer.Write([int16]$blockAlign)
    $writer.Write([int16]$bitsPerSample)

    # data subchunk
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $writer.Write([int32]$subChunk2Size)

    foreach ($s in $Samples) {
        $clamped = [Math]::Max(-1.0, [Math]::Min(1.0, $s))
        $val16 = [int16]($clamped * 32767)
        $writer.Write($val16)
    }

    $writer.Close()
    $stream.Close()
}

$sampleRate = 44100

# 1. ui_hover.wav (70ms soft electronic blip, 900Hz -> 1200Hz, smooth envelope)
$hoverDuration = 0.070
$hoverCount = [int]($sampleRate * $hoverDuration)
$hoverSamples = New-Object float[] $hoverCount
for ($i = 0; $i -lt $hoverCount; $i++) {
    $t = $i / $sampleRate
    $progress = $t / $hoverDuration
    $freq = 900.0 + 300.0 * $progress
    $env = [Math]::Sin($progress * [Math]::PI) # smooth half-sine envelope
    $phase = 2.0 * [Math]::PI * (900.0 * $t + 150.0 * $progress * $t)
    $val = [Math]::Sin($phase) * 0.45 * $env
    $hoverSamples[$i] = $val
}
Write-WavFile -Path "assets/audio/ui_hover.wav" -Samples $hoverSamples -SampleRate $sampleRate

# 2. ui_click.wav (100ms punchy arcade click, 600Hz -> 120Hz rapid decay)
$clickDuration = 0.100
$clickCount = [int]($sampleRate * $clickDuration)
$clickSamples = New-Object float[] $clickCount
for ($i = 0; $i -lt $clickCount; $i++) {
    $t = $i / $sampleRate
    $progress = $t / $clickDuration
    $env = [Math]::Exp(-$progress * 25.0) # fast decay
    $clickImpulse = if ($i -lt 40) { (1.0 - ($i / 40.0)) * 0.8 } else { 0.0 }
    $freq = 600.0 * [Math]::Exp(-$progress * 15.0) + 120.0
    $phase = 2.0 * [Math]::PI * $freq * $t
    $tone = [Math]::Sin($phase) * 0.6
    $val = ($tone * $env) + $clickImpulse
    $clickSamples[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $val * 0.7))
}
Write-WavFile -Path "assets/audio/ui_click.wav" -Samples $clickSamples -SampleRate $sampleRate

# 3. engine.wav (1.0s loopable rumble, 75Hz base + harmonics + sub-bass)
$engineDuration = 1.000
$engineCount = [int]($sampleRate * $engineDuration)
$engineSamples = New-Object float[] $engineCount
$baseFreq = 75.0
for ($i = 0; $i -lt $engineCount; $i++) {
    $t = $i / $sampleRate
    $p1 = 2.0 * [Math]::PI * $baseFreq * $t
    $p2 = 2.0 * [Math]::PI * ($baseFreq * 2.0) * $t
    $p3 = 2.0 * [Math]::PI * ($baseFreq * 3.0) * $t
    $p4 = 2.0 * [Math]::PI * ($baseFreq * 0.5) * $t
    # loop-aligned phase: $engineDuration * $baseFreq = 75.0 cycles exactly!
    $tone = 0.4 * [Math]::Sin($p1) + 0.25 * [Math]::Sin($p2) + 0.15 * [Math]::Sin($p3) + 0.2 * [Math]::Sin($p4)
    # add subtle flutter
    $flutter = 1.0 + 0.1 * [Math]::Sin(2.0 * [Math]::PI * 12.0 * $t)
    $engineSamples[$i] = $tone * $flutter * 0.65
}
Write-WavFile -Path "assets/audio/engine.wav" -Samples $engineSamples -SampleRate $sampleRate

# 4. race_countdown.wav (150ms arcade beep, 880Hz)
$countDuration = 0.150
$countSamplesCount = [int]($sampleRate * $countDuration)
$countSamples = New-Object float[] $countSamplesCount
for ($i = 0; $i -lt $countSamplesCount; $i++) {
    $t = $i / $sampleRate
    $progress = $t / $countDuration
    $env = if ($progress -lt 0.05) { $progress / 0.05 } else { [Math]::Exp(-($progress - 0.05) * 8.0) }
    $phase = 2.0 * [Math]::PI * 880.0 * $t
    $tone = [Math]::Sin($phase) * 0.55 + 0.15 * [Math]::Sin(2.0 * $phase)
    $countSamples[$i] = $tone * $env
}
Write-WavFile -Path "assets/audio/race_countdown.wav" -Samples $countSamples -SampleRate $sampleRate

# 5. race_finish.wav (500ms victory arpeggio: C5(523Hz), E5(659Hz), G5(784Hz), C6(1046Hz))
$finishDuration = 0.550
$finishCount = [int]($sampleRate * $finishDuration)
$finishSamples = New-Object float[] $finishCount
$notes = @(523.25, 659.25, 783.99, 1046.50)
$noteLen = 0.100
for ($i = 0; $i -lt $finishCount; $i++) {
    $t = $i / $sampleRate
    $sum = 0.0
    for ($n = 0; $n -lt $notes.Length; $n++) {
        $startTime = $n * 0.090
        if ($t -ge $startTime) {
            $noteTime = $t - $startTime
            $noteFreq = $notes[$n]
            $noteEnv = [Math]::Exp(-$noteTime * 6.0)
            $sum += [Math]::Sin(2.0 * [Math]::PI * $noteFreq * $noteTime) * 0.3 * $noteEnv
        }
    }
    $finishSamples[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $sum))
}
Write-WavFile -Path "assets/audio/race_finish.wav" -Samples $finishSamples -SampleRate $sampleRate

Get-ChildItem assets/audio
