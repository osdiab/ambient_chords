// impulse to filter to dac

15 => float pitch;
.2 => float pluckProbability;


240::ms => dur clockTick;
[2.5, 5.0, 10.0, 15.0, 22.5, 23.79, 35.63] @=> float minorFreqs[];
[1.985, 3.97, 7.94, 11.89, 17.82, 20, 29.97] @=> float majorFreqs[];
[10.0, 15.0] @=> float baseFreqs[];


20 => int curDuration;
.1 => float curReverb;
0 => float curMajorness;
0 => float curSimplicity;
0 => float curNoisiness;
0 => float curBassiness;
0 => int playing;
.0005 => float curVolume;

HPF hpf;

KBHit kb;

// karmic truisms
["Top"] @=> string topTruisms[];
["Bottom"] @=> string bottomTruisms[];
["Ascend"] @=> string ascentTruisms[];
["Descend"] @=> string descentTruisms[];

fun void triggerNote(int majorFreq, int minorFreq, int baseFreq,
    int randomOctave, int pluck)
{
    curDuration * clockTick => dur duration;
    ADSR adsr;
    Echo echo;
    .1 => adsr.gain;

    Math.random2(0, dac.channels() - 1) => int majorDacChannel;
    Math.random2(0, dac.channels() - 1) => int minorDacChannel;
    Math.random2(0, dac.channels() - 1) => int baseDacChannel;
    SinOsc minorOsc =>  adsr => Chorus majorChorus =>
        echo => hpf => NRev majorReverb =>  dac.chan(majorDacChannel);
    SinOsc majorOsc =>  adsr => Chorus minorChorus =>
        echo => hpf => NRev minorReverb =>  dac.chan(minorDacChannel);
    SinOsc baseOsc =>  adsr => Chorus baseChorus =>
        echo => hpf => NRev baseReverb =>  dac.chan(baseDacChannel);

    .1 => majorChorus.modDepth;
    .1 => minorChorus.modDepth;
    .1 => baseChorus.modDepth;

    (curMajorness * (1 - curSimplicity)) => majorOsc.gain;
    ((1 - curMajorness) * (1 - curSimplicity)) => minorOsc.gain;
    (curSimplicity) => baseOsc.gain;

    (pitch * majorFreqs[majorFreq]) => majorOsc.freq;
    (pitch * minorFreqs[minorFreq]) => minorOsc.freq;
    (pitch * baseFreqs[baseFreq]) => baseOsc.freq;

    clockTick * 2 => echo.delay;

    if (pluck) {
        if (curMajorness > .5) {
            majorOsc.freq() * 2 => majorOsc.freq;
        } else {
            minorOsc.freq() * 2 => minorOsc.freq;
        }

        adsr.set(10::ms, duration, 0, 400::ms);
        curReverb * 2 => majorReverb.mix;
        curReverb * 2 => minorReverb.mix;
        curReverb * 2 => baseReverb.mix;
    } else {
        adsr.set(clockTick * 6, duration, 0, 400::ms);
        curReverb => majorReverb.mix;
        curReverb => minorReverb.mix;
        curReverb => baseReverb.mix;
    }


    adsr.keyOn();
    duration * 1.3 => now;
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
                <<< "majorness: ", spoutKnowledge(old != curMajorness, 1) >>>;
            } else if ('a' == curChar) {
                curMajorness => float old;
                Math.max(0, curMajorness - .1) => curMajorness;
                <<< "majorness: ", spoutKnowledge(old != curMajorness, -1) >>>;
            } else if ('o' == curChar) {
                curSimplicity => float old;
                Math.min(1, curSimplicity + .1) => curSimplicity;
                <<< "simplicity: ", spoutKnowledge(old != curSimplicity, 1) >>>;
            } else if ('l' == curChar) {
                curSimplicity => float old;
                Math.max(0, curSimplicity - .1) => curSimplicity;
                <<< "simplicity: ", spoutKnowledge(old != curSimplicity, -1) >>>;
            } else if ('i' == curChar) {
                curNoisiness => float old;
                Math.min(1, curNoisiness + .1) => curNoisiness;
                <<< "noisiness: ", spoutKnowledge(old != curNoisiness, 1) >>>;
            } else if ('k' == curChar) {
                curNoisiness => float old;
                Math.max(0, curNoisiness - .1) => curNoisiness;
                <<< "noisiness: ", spoutKnowledge(old != curNoisiness, -1) >>>;
            } else if ('w' == curChar) {
                curBassiness => float old;
                Math.min(1, curBassiness + .1) => curBassiness;
                <<< "bassiness: ", spoutKnowledge(old != curBassiness, 1) >>>;
            } else if ('s' == curChar) {
                curBassiness => float old;
                Math.max(0, curBassiness - .1) => curBassiness;
                <<< "bassiness: ", spoutKnowledge(old != curBassiness, -1) >>>;
            } else if ('e' == curChar) {
                curVolume => float old;
                Math.min(.001, curVolume + .00003) => curVolume;
                <<< "volume: ", spoutKnowledge(old != curVolume, 1) >>>;
            } else if ('d' == curChar) {
                curVolume => float old;
                Math.max(0, curVolume - .00003) => curVolume;
                <<< "volume: ", spoutKnowledge(old != curVolume, -1) >>>;
            } else if (' ' == curChar) {
                !playing => playing;
                if (playing) {
                    <<< "|> ", "Now playing." >>>;
                } else {
                    <<< "|| ", "Done playing." >>>;
                }
            }
        }
    }
}

fun void generateNoise()
{
    SubNoise noiseGen => Delay delay => NRev rev => dac;
    .5 => rev.mix;
    50 :: ms => delay.delay;

    while(true)
    {
        curNoisiness * 3 => noiseGen.gain;
        50 :: ms => now;
    }
}

spork ~ keyboardListener();
spork ~ generateNoise();

// infinite time-loop
while (true)
{
    curVolume => dac.gain;

    300 - curBassiness * 240 => hpf.freq;
    Math.random2(0, 6) => int randomInterval;
    Math.random2(0, 5) => int randomOctave;
    Math.random2(0, majorFreqs.size() - 1) => int majorFreq;
    Math.random2(0, minorFreqs.size() - 1) => int minorFreq;
    Math.random2(0, baseFreqs.size() - 1) => int baseFreq;

    if (Math.randomf() < curBassiness / 4) {
        if (curMajorness > .5) {
            Math.random2(0, 3) => int majorFreq;
        } else {
            Math.random2(0, 3) => int minorFreq;
        }
    };

    randomInterval * clockTick => now;

    (Math.randomf() < pluckProbability) => int pluck;
    if (playing) {
        spork ~ triggerNote(majorFreq, minorFreq, baseFreq, randomOctave, pluck);
    }
}
