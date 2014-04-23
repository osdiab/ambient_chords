// impulse to filter to dac

0 => int curSpork;
15 => float pitch;
.2 => float pluckProbability;


240::ms => dur clockTick;
[2.5, 5.0, 10.0, 15.0, 22.5, 23.79, 35.63] @=> float minorFreqs[];
[1.985, 3.97, 7.94, 11.89, 17.82, 20, 29.97] @=> float majorFreqs[];
[10.0, 15.0] @=> float baseFreqs[];

dac.channels() => int numChannels;
NRev reverbs[numChannels];
Echo echos[numChannels];
HPF hpfs[numChannels];

1 => int counter;
15 => int curDuration;
.1 => float curReverb;
0 => float curMajorness;
0 => float curSimplicity;
0 => float curNoisiness;
0 => float curBassiness;
0 => int playing;
1 => float maxVolume;
1 => float curVolume;
.05 => float volFactor;

KBHit kb;

// karmic truisms
["Top"] @=> string topTruisms[];
["Bottom"] @=> string bottomTruisms[];
["Ascend"] @=> string ascentTruisms[];
["Descend"] @=> string descentTruisms[];

fun void triggerNote(int majorFreq, int minorFreq, int baseFreq,
    int pluck)
{
    curDuration * clockTick => dur duration;
    ADSR adsr;
    adsr.set(clockTick * 6, duration, 0, 400::ms);
    volFactor => adsr.gain;

    Math.random2(0, numChannels - 1) => int majorDacChannel;
    Math.random2(0, numChannels - 1) => int minorDacChannel;
    Math.random2(0, numChannels - 1) => int baseDacChannel;

    SinOsc minorOsc => adsr =>
        echos[majorDacChannel] => hpfs[majorDacChannel] =>
        reverbs[majorDacChannel] =>  dac.chan(majorDacChannel);
    (pitch * minorFreqs[minorFreq]) => minorOsc.freq;
    ((1 - curMajorness) * (1 - curSimplicity)) * volFactor => minorOsc.gain;

    SinOsc majorOsc => adsr =>
        echos[minorDacChannel] => hpfs[minorDacChannel]
        => reverbs[minorDacChannel] =>  dac.chan(minorDacChannel);
    (pitch * majorFreqs[majorFreq]) => majorOsc.freq;
    (curMajorness * (1 - curSimplicity)) * volFactor => majorOsc.gain;

    SinOsc baseOsc => adsr =>
        echos[baseDacChannel] => hpfs[baseDacChannel] =>
        reverbs[baseDacChannel] =>  dac.chan(baseDacChannel);
    (pitch * baseFreqs[baseFreq]) => baseOsc.freq;
    (curSimplicity) * volFactor => baseOsc.gain;

    if (pluck) {
        if (curMajorness > .5) {
            majorOsc.freq() * 2 => majorOsc.freq;
        } else {
            minorOsc.freq() * 2 => minorOsc.freq;
        }

        adsr.set(10::ms, duration, 0, 400::ms);
    }

    adsr.keyOn();
    duration * 1.5 => now;
    adsr.keyOff();
    500::ms => now;

    minorOsc =< dac;
    majorOsc =< dac;
    baseOsc =< dac;
    adsr =< dac;
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
    <<< "\n", "majorness: + q, - a.\n", "simplicity: +o, -l\n", "noisiness: +i, -k\n",
    "bassiness: +w, -s\n", "volume: +e, -d\n", "space: play/pause" >>>;
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
                curVolume => float oldVolume;
                Math.min(maxVolume, curVolume + (maxVolume / 50)) => float newVolume;
                Std.fabs(newVolume - oldVolume) / 10 => float stepSize;
                while (curVolume < newVolume) {
                    Math.min(curVolume + stepSize, newVolume) => curVolume;
                    curVolume => dac.gain;
                    20 :: ms => now;
                }
                <<< "volume: ", curVolume, spoutKnowledge(oldVolume != newVolume, 1) >>>;
            } else if ('d' == curChar) {
                curVolume => float oldVolume;
                Math.max(0, curVolume - (maxVolume / 50)) => float newVolume;
                Std.fabs(newVolume - oldVolume) / 10 => float stepSize;
                while (curVolume > newVolume) {
                    Math.max(curVolume - stepSize, newVolume) => curVolume;
                    curVolume => dac.gain;
                    20 :: ms => now;
                }

                <<< "volume: ", curVolume, spoutKnowledge(oldVolume != curVolume, -1) >>>;
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

for (0 => int i; i < numChannels; i++) {
    curReverb => reverbs[i].mix;
    volFactor => reverbs[i].gain;

    clockTick * 2 => echos[i].delay;
    volFactor => echos[i].gain;

    volFactor => hpfs[i].gain;
}

curVolume => float prevVolume;
curVolume => dac.gain;

curBassiness => float prevBassiness;
for (0 => int i; i < numChannels; i++) {
    300 - curBassiness * 240 => hpfs[i].freq;
}

// infinite time-loop
while (true)
{
    if (curVolume != prevVolume) {
        curVolume => dac.gain;
        curVolume => prevVolume;
        <<< "curVolume gain: ", dac.gain() >>>;
    }

    if (curBassiness != prevBassiness) {
        for (0 => int i; i < numChannels; i++) {
            300 - curBassiness * 240 => hpfs[i].freq;
        }
        curBassiness => prevBassiness;
    }

    Math.random2(2, 6) => int randomInterval;
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
        spork ~ triggerNote(majorFreq, minorFreq, baseFreq, pluck);
    }
}
