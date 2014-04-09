// impulse to filter to dac

15 => float pitch;
.2 => float pluckProbability;
240::ms => dur clockTick;
[10, 12, 15, 18, 20, 24] @=> int freqs[];
//[10.0, 12.0, 15, 16.0] @=> float freqs[];
//[10, 12, 15, 17] @=> int freqs[];

fun void triggerNote(int freq, int randomOctave, int pluck)
{
    clockTick * 20 => dur duration;
    SinOsc osc => BPF bandpass => ADSR adsr => Chorus chorus => Gain oscGain =>
        Echo echo => JCRev reverb => dac;

    .1 => oscGain.gain;
    .1 => chorus.modDepth;

    (pitch * freqs[freq]) => osc.freq;

    300 => bandpass.freq;
    1 => bandpass.Q;

    if (pluck) {
        osc.freq() * 2 => osc.freq;
        adsr.set(20::ms, duration, 0, 0::ms);
    } else {
        adsr.set(clockTick * 6, duration, 0, 0::ms);
    }

    .5 => reverb.mix;

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
    randomInterval * clockTick => now;

    (Math.randomf() < pluckProbability) => int pluck;
    spork ~ triggerNote(randomFreq, randomOctave, pluck);
}
