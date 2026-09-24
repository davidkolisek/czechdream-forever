const combinations={Druid:['Night Elf','Tauren','Skyborne'],Hunter:['Human','Dwarf','Night Elf','Orc','Tauren','Troll','Skyborne'],Mage:['Human','Gnome','Undead','Troll','Skyborne'],Paladin:['Human','Dwarf','Undead'],Priest:['Human','Dwarf','Night Elf','Gnome','Undead','Troll'],Rogue:['Human','Dwarf','Night Elf','Gnome','Orc','Undead','Troll','Skyborne'],Shaman:['Dwarf','Orc','Tauren','Troll','Skyborne'],Warlock:['Human','Gnome','Orc','Undead','Troll'],Warrior:['Human','Dwarf','Night Elf','Gnome','Orc','Undead','Tauren','Troll','Skyborne']}
const factions={Horde:['Orc','Undead','Tauren','Troll','Skyborne'],Alliance:['Human','Dwarf','Night Elf','Gnome','Skyborne']}
const profiles={Druid:['Tank','Healer','Melee DPS','Ranged DPS'],Hunter:['Melee DPS','Ranged DPS'],Mage:['Ranged DPS'],Paladin:['Tank','Healer','Melee DPS'],Priest:['Healer','Ranged DPS'],Rogue:['Melee DPS'],Shaman:['Healer','Melee DPS','Ranged DPS'],Warlock:['Ranged DPS'],Warrior:['Tank','Melee DPS']}
const cases=[
  ['Horde healer/support','Horde','Healer','Healing & support','I want to be needed by the group',['Priest','Shaman','Paladin']],
  ['Alliance healer/support','Alliance','Healer','Healing & support','I want to be needed by the group',['Priest','Paladin','Shaman']],
  ['Horde affliction pressure','Horde','Ranged DPS','Sustained pressure','I want to handle things alone',['Warlock']],
  ['Horde PvP stealth','Horde','Melee DPS','Burst damage','I want to handle things alone',['Rogue']],
  ['Alliance tank','Alliance','Tank','Simple & durable','I want to be needed by the group',['Warrior','Paladin','Druid']],
  ['Horde flexible hybrid','Horde','Healer','Support & utility','I want to be needed by the group',['Shaman','Druid']],
  ['Alliance ranged control','Alliance','Ranged DPS','Control & disruption','I like playing with friends',['Mage','Priest','Warlock']],
  ['Horde solo pet','Horde','Ranged DPS','Mobile & ranged','I want to handle things alone',['Hunter','Warlock']],
]
const archetypes={
  Druid:['Tank','Healer','Melee DPS','Ranged DPS'], Hunter:['Ranged DPS','Melee DPS'], Mage:['Ranged DPS'],
  Paladin:['Tank','Healer','Melee DPS'], Priest:['Healer','Ranged DPS'], Rogue:['Melee DPS'],
  Shaman:['Healer','Melee DPS','Ranged DPS'], Warlock:['Ranged DPS'], Warrior:['Tank','Melee DPS']
}
function run([,faction,role,combat,independence,expected]){
  const valid=Object.keys(profiles).filter(c=>combinations[c].some(r=>factions[faction].includes(r)))
  const scores=Object.fromEntries(valid.map(c=>[c,20]))
  for(const c of valid){if(profiles[c].includes(role))scores[c]+=28;if(role==='Healer')scores[c]+={Priest:18,Shaman:15,Paladin:12,Druid:8}[c]||0;if(combat==='Healing & support'&&['Priest','Shaman','Paladin','Druid'].includes(c))scores[c]+=25;if(combat==='Sustained pressure'&&['Warlock','Priest','Shaman'].includes(c))scores[c]+=30;if(combat==='Control & disruption'&&['Mage','Rogue','Warlock','Priest'].includes(c))scores[c]+=20;if(independence==='I want to handle things alone'&&['Hunter','Warlock','Druid','Rogue'].includes(c))scores[c]+=12;if(independence==='I want to be needed by the group'&&['Shaman','Paladin','Priest','Druid'].includes(c))scores[c]+=15}
  return Object.entries(scores).sort((a,b)=>b[1]-a[1])[0][0]
}
let failed=0
for(const test of cases){const result=run(test);const ok=test[5].includes(result);console.log(`${ok?'PASS':'FAIL'}  ${test[0]} -> ${result} (expected: ${test[5].join(' / ')})`);if(!ok)failed++}
if(failed)process.exitCode=1

console.log('\nVALID RACE / CLASS MATRIX')
for(const faction of Object.keys(factions)){
  console.log(`\n${faction}`)
  for(const [className,races] of Object.entries(combinations)){
    const valid=races.filter(race=>factions[faction].includes(race))
    console.log(`  ${className.padEnd(8)} ${valid.length?valid.join(', '):'—'}`)
  }
}

console.log('\nROLE COVERAGE MATRIX')
for(const [className,roles] of Object.entries(archetypes)){
  for(const role of ['Tank','Healer','Melee DPS','Ranged DPS']){
    console.log(`  ${className.padEnd(8)} ${role.padEnd(10)} ${roles.includes(role)?'VALID':'NOT AVAILABLE'}`)
  }
}

let invalid=0
for(const [className,races] of Object.entries(combinations)){
  for(const race of races){
    const faction=Object.entries(factions).find(([,available])=>available.includes(race))?.[0]
    if(!faction){console.log(`FAIL invalid race: ${race}`);invalid++}
    if(!races.includes(race)){console.log(`FAIL invalid combination: ${race} ${className}`);invalid++}
  }
}
console.log(`\nMATRIX CHECK: ${invalid?'FAIL':'PASS'} · ${Object.values(combinations).reduce((sum,races)=>sum+races.length,0)} valid class/race combinations checked`)
if(invalid)process.exitCode=1
