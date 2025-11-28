local soundHelper = {}

-- Common sound generation constants
local SAMPLE_RATE = 44100
local BIT_DEPTH = 4 -- Retro lo-fi quantization
local CHANNELS = 1 -- Mono
local BITS_PER_SAMPLE = 16

---Generate a retro 8-bit style sound effect using a factory pattern.
---@param opts table Sound generation parameters with fields:
---   duration (number): Duration in seconds
---   frequencies (table): Array of {baseFreq, sweepAmount} pairs for each oscillator
---   amplitudes (table): Array of amplitudes for each oscillator (should match frequencies length)
---   noiseAmount (number): Amount of white noise (0-1)
---   attackTime (number): Envelope attack time in seconds
---   decayRate (number): Envelope decay rate (higher = faster decay). Set to 0 for no decay (looping sounds)
---   volume (number): Volume (0-1)
---   looping (boolean): If true, no decay envelope applied (for seamless looping)
---@return table soundSource
function soundHelper.generateRetroSound(opts)
    opts = opts or {}
    local duration = opts.duration or 0.08
    local frequencies = opts.frequencies or {{300, 400}, {200, 300}, {150, 200}}
    local amplitudes = opts.amplitudes or {0.4, 0.3, 0.2}
    local noiseAmount = opts.noiseAmount or 0.2
    local attackTime = opts.attackTime or 0.005
    local decayRate = opts.decayRate or 15
    local volume = opts.volume or 0.5
    local looping = opts.looping or false

    local sampleCount = math.floor(SAMPLE_RATE * duration)
    local soundData = love.sound.newSoundData(sampleCount, SAMPLE_RATE, BITS_PER_SAMPLE, CHANNELS)

    -- Generate retro-style sound
    for i = 0, sampleCount - 1 do
        local t = i / SAMPLE_RATE

        -- Generate square waves for each frequency
        local wave = 0.0
        for j = 1, #frequencies do
            local baseFreq = frequencies[j][1]
            local sweepAmount = frequencies[j][2]
            local freq = baseFreq + (t * sweepAmount)
            local phase = (freq * t) % 1.0
            local square = (phase < 0.5) and 1.0 or -1.0
            local amplitude = amplitudes[j] or 0.3
            wave = wave + (square * amplitude)
        end

        -- Add white noise for texture
        local noise = (math.random() - 0.5) * noiseAmount

        -- Apply envelope: attack and decay (skip decay for looping sounds)
        local envelope
        if looping then
            -- For looping sounds, only apply quick attack at start, no decay
            if t < attackTime then
                envelope = t / attackTime
            else
                envelope = 1.0
            end
        else
            -- Normal envelope with decay
            if t < attackTime then
                envelope = t / attackTime
            else
                envelope = math.exp(-t * decayRate)
            end
        end

        -- Combine components
        local sample = (wave + noise) * envelope

        -- Bitcrushing effect for retro lo-fi sound
        sample = math.floor(sample * BIT_DEPTH) / BIT_DEPTH

        -- Clamp to valid range
        sample = math.max(-1.0, math.min(1.0, sample))

        soundData:setSample(i, sample)
    end

    -- Create source and set volume
    local source = love.audio.newSource(soundData)
    source:setVolume(volume)
    return source
end

---Generate a retro 8-bit style attack sound effect programmatically.
---Creates a punchy, chiptune-style "whoosh" sound.
---@return table soundSource
function soundHelper.generateAttackSound()
    return soundHelper.generateRetroSound({
        duration = 0.08,
        frequencies = {{300, 400}, {200, 300}, {150, 200}},
        amplitudes = {0.4, 0.3, 0.2},
        noiseAmount = 0.2,
        attackTime = 0.005,
        decayRate = 15,
        volume = 0.5,
    })
end

---Generate a retro miss/whiff sound effect programmatically.
---Creates a short, lower-pitched "whoosh" sound for missed attacks.
---@return table soundSource
function soundHelper.generateMissSound()
    return soundHelper.generateRetroSound({
        duration = 0.06,
        frequencies = {{150, 200}, {100, 150}, {80, 100}},
        amplitudes = {0.3, 0.2, 0.15},
        noiseAmount = 0.1,
        attackTime = 0.005,
        decayRate = 20,
        volume = 0.35,
    })
end

---Play an attack sound effect.
---Generates and plays a new attack sound each time.
function soundHelper.playAttackSound()
    local source = soundHelper.generateAttackSound()
    love.audio.play(source)
end

---Play a miss sound effect.
---Generates and plays a new miss sound each time.
function soundHelper.playMissSound()
    local source = soundHelper.generateMissSound()
    love.audio.play(source)
end

---Generate a retro fireball travel sound effect.
---Creates a continuous whooshing sound for a travelling fireball.
---@return table soundSource
function soundHelper.generateFireballTravelSound()
    return soundHelper.generateRetroSound({
        duration = 3.0, -- Much longer for smoother looping
        frequencies = {{400, 20}, {300, 15}, {250, 10}}, -- Much slower frequency sweeps
        amplitudes = {0.25, 0.2, 0.15},
        noiseAmount = 0.15,
        attackTime = 0.01,
        decayRate = 0, -- No decay for seamless looping
        volume = 0.3,
        looping = true, -- Mark as looping sound
    })
end

---Generate a retro fireball impact/explosion sound effect.
---Creates a fire-like crackling explosion sound for when fireball hits.
---@return table soundSource
function soundHelper.generateFireballImpactSound()
    local duration = 0.15
    local sampleCount = math.floor(SAMPLE_RATE * duration)
    local soundData = love.sound.newSoundData(sampleCount, SAMPLE_RATE, BITS_PER_SAMPLE, CHANNELS)

    -- Generate fire explosion sound
    for i = 0, sampleCount - 1 do
        local t = i / SAMPLE_RATE

        -- Explosion frequencies (start high, descend)
        local freq1 = 400 - (t * 300) + (math.random() - 0.5) * 50
        local freq2 = 250 - (t * 200) + (math.random() - 0.5) * 40
        local freq3 = 150 - (t * 100) + (math.random() - 0.5) * 30

        -- Generate square waves
        local phase1 = (freq1 * t) % 1.0
        local phase2 = (freq2 * t) % 1.0
        local phase3 = (freq3 * t) % 1.0

        local square1 = (phase1 < 0.5) and 1.0 or -1.0
        local square2 = (phase2 < 0.5) and 1.0 or -1.0
        local square3 = (phase3 < 0.5) and 1.0 or -1.0

        -- Mix waves (stronger for explosion)
        local wave = (square1 * 0.3 + square2 * 0.25 + square3 * 0.2)

        -- Intense crackling burst (fire explosion)
        local crackle = (math.random() - 0.5) * 0.5
        -- Hissing burst
        local hiss = (math.random() - 0.5) * 0.3

        -- Explosion envelope: quick attack, fast decay
        local envelope
        if t < 0.003 then
            envelope = t / 0.003
        else
            envelope = math.exp(-t * 18)
        end

        -- Combine: wave + crackle + hiss with envelope
        local sample = (wave + crackle + hiss) * envelope

        -- Bitcrushing for retro lo-fi fire sound
        sample = math.floor(sample * BIT_DEPTH) / BIT_DEPTH

        -- Clamp to valid range
        sample = math.max(-1.0, math.min(1.0, sample))

        soundData:setSample(i, sample)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.65)
    return source
end

---Play a fireball travel sound effect.
---Generates and plays a looping travel sound.
---@return table soundSource The sound source (for stopping later)
function soundHelper.playFireballTravelSound()
    local source = soundHelper.generateFireballTravelSound()
    source:setLooping(true)
    source:setVolume(0.3)
    love.audio.play(source)
    return source
end

---Play a fireball impact sound effect.
---Generates and plays a new impact sound each time.
function soundHelper.playFireballImpactSound()
    local source = soundHelper.generateFireballImpactSound()
    love.audio.play(source)
end

---Generate a retro thunder travel sound effect.
---Creates a building electrical rumble as lightning descends from the sky.
---@return table soundSource
function soundHelper.generateThunderTravelSound()
    local duration = 0.6 -- Match thunder spell lifetime
    local sampleCount = math.floor(SAMPLE_RATE * duration)
    local soundData = love.sound.newSoundData(sampleCount, SAMPLE_RATE, BITS_PER_SAMPLE, CHANNELS)

    -- Generate building electrical rumble
    for i = 0, sampleCount - 1 do
        local t = i / SAMPLE_RATE
        local progress = t / duration -- 0 to 1

        -- Low rumbling frequencies that build up
        local freq1 = 60 + (progress * 40) + math.sin(t * 3) * 10
        local freq2 = 40 + (progress * 30) + math.sin(t * 5) * 8
        local freq3 = 25 + (progress * 20) + math.sin(t * 7) * 5

        -- Generate square waves
        local phase1 = (freq1 * t) % 1.0
        local phase2 = (freq2 * t) % 1.0
        local phase3 = (freq3 * t) % 1.0

        local square1 = (phase1 < 0.5) and 1.0 or -1.0
        local square2 = (phase2 < 0.5) and 1.0 or -1.0
        local square3 = (phase3 < 0.5) and 1.0 or -1.0

        -- Mix waves (building intensity)
        local wave = (square1 * 0.2 + square2 * 0.15 + square3 * 0.1) * (0.5 + progress * 0.5)

        -- Electrical crackling (sparse, building up)
        local crackle = 0
        if math.random() < (0.1 + progress * 0.3) then
            crackle = (math.random() - 0.5) * 0.3 * progress
        end

        -- High frequency electrical buzz (builds up)
        local buzzFreq = 800 + (progress * 400)
        local buzzPhase = (buzzFreq * t) % 1.0
        local buzz = ((buzzPhase < 0.5) and 1.0 or -1.0) * 0.1 * progress

        -- Building envelope
        local envelope = 0.3 + (progress * 0.7)

        -- Combine: rumble + crackle + buzz
        local sample = (wave + crackle + buzz) * envelope

        -- Bitcrushing for retro lo-fi sound
        sample = math.floor(sample * BIT_DEPTH) / BIT_DEPTH

        -- Clamp to valid range
        sample = math.max(-1.0, math.min(1.0, sample))

        soundData:setSample(i, sample)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.4)
    return source
end

---Generate a retro thunder impact sound effect.
---Creates a powerful thunder crack/boom when lightning strikes.
---@return table soundSource
function soundHelper.generateThunderImpactSound()
    local duration = 0.2
    local sampleCount = math.floor(SAMPLE_RATE * duration)
    local soundData = love.sound.newSoundData(sampleCount, SAMPLE_RATE, BITS_PER_SAMPLE, CHANNELS)

    -- Generate thunder crack sound
    for i = 0, sampleCount - 1 do
        local t = i / SAMPLE_RATE

        -- Thunder frequencies: sharp crack then deep rumble
        local freq1 = 600 - (t * 550) -- Sharp crack descending to rumble
        local freq2 = 400 - (t * 350)
        local freq3 = 200 - (t * 150)

        -- Generate square waves
        local phase1 = (freq1 * t) % 1.0
        local phase2 = (freq2 * t) % 1.0
        local phase3 = (freq3 * t) % 1.0

        local square1 = (phase1 < 0.5) and 1.0 or -1.0
        local square2 = (phase2 < 0.5) and 1.0 or -1.0
        local square3 = (phase3 < 0.5) and 1.0 or -1.0

        -- Mix waves (strong for thunder)
        local wave = (square1 * 0.4 + square2 * 0.35 + square3 * 0.3)

        -- Sharp electrical crack (initial strike)
        local crack = 0
        if t < 0.01 then
            crack = (math.random() - 0.5) * 0.6
        end

        -- Deep rumble (thunder boom)
        local rumbleFreq = 30 + (math.random() - 0.5) * 10
        local rumblePhase = (rumbleFreq * t) % 1.0
        local rumble = ((rumblePhase < 0.5) and 1.0 or -1.0) * 0.25

        -- Thunder envelope: instant crack, then deep rumble decay
        local envelope
        if t < 0.005 then
            envelope = 1.0 -- Instant crack
        else
            envelope = math.exp(-t * 8) -- Deep rumble decay
        end

        -- Combine: wave + crack + rumble
        local sample = (wave + crack + rumble) * envelope

        -- Bitcrushing for retro lo-fi sound
        sample = math.floor(sample * BIT_DEPTH) / BIT_DEPTH

        -- Clamp to valid range
        sample = math.max(-1.0, math.min(1.0, sample))

        soundData:setSample(i, sample)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.7) -- Loud thunder!
    return source
end

---Play a thunder travel sound effect.
---Generates and plays a travel sound for descending lightning.
---@return table soundSource The sound source (for stopping later)
function soundHelper.playThunderTravelSound()
    local source = soundHelper.generateThunderTravelSound()
    source:setVolume(0.4)
    love.audio.play(source)
    return source
end

---Play a thunder impact sound effect.
---Generates and plays a new thunder crack sound each time.
function soundHelper.playThunderImpactSound()
    local source = soundHelper.generateThunderImpactSound()
    love.audio.play(source)
end

return soundHelper
