// impulse to filter to dac

15 => float pitch;
.2 => float pluckProbability;
.010 => float volume;

240::ms => dur clockTick;
[10.0, 15.0, 22.5, 23.79, 35.63] @=> float minorFreqs[];
[7.94, 11.89, 17.82, 20, 29.97] @=> float majorFreqs[];
[10.0, 15.0] @=> float baseFreqs[];


20 => int curDuration;
.1 => float curReverb;
0 => float curMajorness;
0 => float curBaseness;

KBHit kb;

// karmic truisms
["Top"] @=> string topTruisms[];
["Bottom"] @=> string bottomTruisms[];
["Ascend"] @=> string ascentTruisms[];
["Descend"] @=> string descentTruisms[];

fun void triggerNote(int majorFreq, int minorFreq, int baseFreq,
    int randomOctave, int pluck, int dacChannel)
{
    curDuration * clockTick => dur duration;
    BPF bandpass;
    ADSR adsr;
    Echo echo;

    SinOsc minorOsc => bandpass => adsr => Chorus majorChorus =>
        echo => NRev majorReverb => dac.chan(dacChannel);
    SinOsc majorOsc => bandpass => adsr => Chorus minorChorus =>
        echo => NRev minorReverb => dac.chan(dacChannel);
    SinOsc baseOsc => bandpass => adsr => Chorus baseChorus =>
        echo => NRev baseReverb => dac.chan(dacChannel);

    .1 => majorChorus.modDepth;
    .1 => minorChorus.modDepth;
    .1 => baseChorus.modDepth;

    (volume * curMajorness * (1 - curBaseness)) => majorOsc.gain;
    (volume * (1 - curMajorness) * (1 - curBaseness)) => minorOsc.gain;
    (volume * curBaseness) => baseOsc.gain;

    (pitch * majorFreqs[majorFreq]) => majorOsc.freq;
    (pitch * minorFreqs[minorFreq]) => minorOsc.freq;
    (pitch * baseFreqs[baseFreq]) => baseOsc.freq;

    300 => bandpass.freq;
    1 => bandpass.Q;
    clockTick * 2 => echo.delay;

    if (pluck) {
        if (curMajorness > .5) {
            majorOsc.freq() * 2 => majorOsc.freq;
        } else {
            minorOsc.freq() * 2 => minorOsc.freq;
        }

        adsr.set(10::ms, duration, 0, 0::ms);
        curReverb * 2 => majorReverb.mix;
        curReverb * 2 => minorReverb.mix;
        curReverb * 2 => baseReverb.mix;
    } else {
        adsr.set(clockTick * 6, duration, 0, 0::ms);
        curReverb => majorReverb.mix;
        curReverb => minorReverb.mix;
        curReverb => baseReverb.mix;
    }


    adsr.keyOn();
    duration => now;
    adsr.keyOff();
}

fun string spoutKnowledge(int change, int intent)
{
    if (intent < 0) {
        if (change) {
            return descentTruisms[Math.random2(0, descentTruisms.size() - 1)];
        } else {
            return bottomTruisms[Math.random2(0, bottomTruisms.size() - 1)];
        }
    } else {
        if (change) {
            return ascentTruisms[Math.random2(0, ascentTruisms.size() - 1)];
        } else {
            return topTruisms[Math.random2(0, topTruisms.size() - 1)];
        }
    }
}

fun void keyboardListener()
{
    while (true)
    {
        kb => now;
        while (kb.more())
        {
            kb.getchar() => int curChar;
            if ('q' == curChar) {
                curMajorness => float old;
                Math.min(1, curMajorness + .1) => curMajorness;
                <<< spoutKnowledge(old != curMajorness, 1) >>>;
            } else if ('a' == curChar) {
                curMajorness => float old;
                Math.max(0, curMajorness - .1) => curMajorness;
                <<< spoutKnowledge(old != curMajorness, -1) >>>;
            } else if ('o' == curChar) {
                curBaseness => float old;
                Math.min(1, curBaseness + .1) => curBaseness;
                <<< spoutKnowledge(old != curBaseness, 1) >>>;
            } else if ('l' == curChar) {
                curBaseness => float old;
                Math.max(0, curBaseness - .1) => curBaseness;
                <<< spoutKnowledge(old != curBaseness, -1) >>>;
            } else if ('i' == curChar) {
                curDuration => int old;
                Math.min(40, curDuration + 2) $ int => curDuration;
                <<< spoutKnowledge(old != curDuration, 1) >>>;
            } else if ('k' == curDuration) {
                curDuration => int old;
                Math.max(10, curDuration - 2) $ int => curDuration;
                <<< spoutKnowledge(old != curDuration, -1) >>>;
            }
        }
    }
}

spork ~ keyboardListener();

// infinite time-loop
while (true)
{
    Math.random2(0, 6) => int randomInterval;
    Math.random2(0, 5) => int randomOctave;
    Math.random2(0, majorFreqs.size() - 1) => int majorFreq;
    Math.random2(0, minorFreqs.size() - 1) => int minorFreq;
    Math.random2(0, baseFreqs.size() - 1) => int baseFreq;
    Math.random2(0, dac.channels() - 1) => int dacChannel;

    randomInterval * clockTick => now;

    (Math.randomf() < pluckProbability) => int pluck;
    spork ~ triggerNote(majorFreq, minorFreq, baseFreq, randomOctave, pluck, dacChannel);
}
