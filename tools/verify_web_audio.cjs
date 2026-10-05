// Exercise the actual bundled SampleNode, not a reimplementation of its pause logic.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const bundle = fs.readFileSync(path.join(__dirname, '../dist/index.js'), 'utf8');
const start = bundle.indexOf('SampleNode:class SampleNode{');
const end = bundle.indexOf('},deleteSampleNode:', start);
assert(start >= 0 && end > start, 'Expected Godot 4.5.1 SampleNode');
let allocations = 0, starts = 0, stops = 0;
function source() {
 allocations++;
 return {connect(){}, disconnect(){}, addEventListener(){}, removeEventListener(){},
  start(){starts++;}, stop(){stops++;}, buffer:null};
}
const context = {GodotAudio:{ctx:{currentTime:5, createBufferSource:source}}};
const SampleNode = vm.runInNewContext('(' + bundle.slice(start + 'SampleNode:'.length, end + 1) + ')', context);
const node = Object.create(SampleNode.prototype);
Object.assign(node, {_source:source(), _sampleNodeBuses:new Map(), _positionWorklet:null,
 _onended:null, isStarted:true, isPaused:false, pauseTime:0, startTime:0,
 offset:0, _sourceStartTime:0, getPlaybackRate:()=>1,
 getSample:()=>({getAudioBuffer:()=>({}),loopMode:'forward'})});
for (let frame=0;frame<1200;frame++) node.pause(false);
console.log(`1200 redundant resumes: ${allocations-1} new sources / ${starts} restarts`);
assert.equal(allocations,1,'Playing audio must not be recreated on repeated resume');
for (let frame=0;frame<1200;frame++) node.pause(true);
assert.equal(stops,1,'Paused audio must be stopped once');
const pauseTime = node.pauseTime;
node.pause(false);
assert.equal(starts,1,'A real resume starts exactly one source');
assert(pauseTime>0 && !node.isPaused,'Actual pause/resume preserves its transition');
for (let frame=0;frame<1200;frame++) node.pause(false);
assert.equal(starts,1,'Subsequent frames must not restart a resumed sound');
console.log('Web audio: steady playback, repeated pause and actual resume passed.');
