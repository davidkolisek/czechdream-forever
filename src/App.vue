<script setup lang="ts">
import { ref } from 'vue'
const online = ref(false)
const stats = [
  { label: 'Aktívni hráči', value: '0', tone: 'blue' },
  { label: 'Eventy dnes', value: '0', tone: 'purple' },
  { label: 'Úroveň guildy', value: '—', tone: 'gold' },
]
</script>

<template>
  <main class="shell">
    <aside class="sidebar"><div class="brand"><span class="crest">C</span><div><strong>CzechDream</strong><small>FOREVER</small></div></div><nav><a class="active">Prehľad</a><a>Guilda</a><a>Postavy</a><a>Eventy</a><a>Štatistiky</a></nav><div class="status"><i :class="{ online }"></i>{{ online ? 'Bridge online' : 'Bridge čaká na pripojenie' }}</div></aside>
    <section class="content"><header><div><p class="eyebrow">CZECHDREAM FOREVER</p><h1>Guild prehľad</h1><p class="muted">Tvoje dobrodružstvo, na jednom mieste.</p></div><button class="connect" @click="online = !online">{{ online ? 'Bridge pripojený' : 'Pripojiť bridge' }}</button></header>
      <div class="cards"><article v-for="item in stats" :key="item.label" class="card"><span :class="['icon', item.tone]">✦</span><div><small>{{ item.label }}</small><strong>{{ item.value }}</strong></div></article></div>
      <div class="grid"><article class="panel welcome"><p class="eyebrow">VÍTAJ SPÄŤ</p><h2>Pripravení na ďalší raid?</h2><p class="muted">Pripoj WoW addon cez CzechDream Bridge a tvoje postavy, eventy a progres sa začnú zobrazovať tu.</p><button class="primary" @click="online = true">Začať synchronizáciu <span>→</span></button></article><article class="panel"><div class="panel-head"><h3>Posledné eventy</h3><span class="muted">Zatiaľ žiadne</span></div><div class="empty">Eventy sa zobrazia po prvej synchronizácii.</div></article></div>
    </section>
  </main>
</template>
