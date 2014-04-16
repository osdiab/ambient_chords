// impulse to filter to dac

15 => float pitch;
.2 => float pluckProbability;
240::ms => dur clockTick;
[10.0, 15.0, 22.5, 23.79, 35.63] @=> float freqs[];
clockTick * 20 => dur curDuration;
.1 => float curReverb;

//[10.0, 12.0, 15, 16.0] @=> float freqs[];
//[10, 12, 15, 17] @=> int freqs[];

fun void triggerNote(int freq, int randomOctave, int pluck, int dacChannel)
{
    curDuration => dur duration;
    SinOsc osc => BPF bandpass => ADSR adsr => Chorus chorus =>
        Echo echo => NRev reverb => dac.chan(dacChannel);

    .025 => float volume;
    volume => osc.gain;
    .1 => chorus.modDepth;

    (pitch * freqs[freq]) => osc.freq;

    300 => bandpass.freq;
    1 => bandpass.Q;

    if (pluck) {
        osc.freq() * 2 => osc.freq;
        adsr.set(10::ms, duration, 0, 0::ms);
    } else {
        adsr.set(clockTick * 6, duration, 0, 0::ms);
    }

    curReverb => reverb.mix;

    echo.delay(clockTick * 2);

    adsr.keyOn();
    duration => now;
    adsr.keyOff();
}


// infinite time-loop
while (true)
{
    Math.random2(0, 6) => int randomInterval;
    Math.random2(0, 5) => int randomOctave;
    Math.random2(0, freqs.size() - 1) => int randomFreq;
    Math.random2(0, dac.channels() - 1) => int dacChannel;

    randomInterval * clockTick => now;

    (Math.randomf() < pluckProbability) => int pluck;
    spork ~ triggerNote(randomFreq, randomOctave, pluck, dacChannel);
}
