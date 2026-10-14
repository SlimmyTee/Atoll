import re

with open("scratch/stitch/screen.html", "r") as f:
    html = f.read()

# 1. Update <head> with title, SEO, and GA4
ga4_head = """  <title>Atoll — Dynamic Island for your Mac | Native macOS 14 & 15</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Turn your camera notch into a fluid, living command deck. Effortless Spotify & Apple Music controls, 1-click meeting joins, temporary drag & drop pocket, and focus timers.">
  <meta property="og:title" content="Atoll — Dynamic Island for your Mac">
  <meta property="og:description" content="Turn your camera notch into a fluid, living command deck. Native Swift, 0.0% idle CPU, macOS Sonoma & Sequoia.">
  <meta property="og:image" content="assets/stitch_wallpaper.jpg">
  <link rel="icon" type="image/png" href="assets/stitch_logo.png">

  <!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-G97ZKWS05T"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-G97ZKWS05T');

    function trackEvent(action, category, label) {
      if (typeof gtag === 'function') {
        gtag('event', action, {
          event_category: category,
          event_label: label
        });
      }
    }
  </script>
"""
html = html.replace('<link href="https://fonts.googleapis.com', ga4_head + '\n  <link href="https://fonts.googleapis.com', 1)

# 2. Localize image URLs
html = html.replace("https://lh3.googleusercontent.com/aida/AEtjO1UivjJ3s30bS-BZAqz4x6ZPTvcBjl8h56Hnu89nJLsb-M28N_zIJhKIhV1AT9lblBhejoRIEM-gLVc3iy8XKXnRysMyFQoLK6XCpydRxNOo8Y-y9VporKarJNEK2SbL6WMMZKHruMo4vQHwo41lVHAguJQxRlwY9TdGqStjfnZ3SOWFfYYviA9brQXvXd4APbgZzOWdL957ZYjtU5Y5Wy9W9SVStzdqLouqEZzBvyGfBmfSouC0SKQEc5E", "assets/stitch_logo.png")
html = html.replace("https://lh3.googleusercontent.com/aida-public/AB6AXuAoyx2MoJ3GQBtf9jD5a1f26GSeYplcrIdVAeE04IGqQpNkSiTlDckgR0HZ6PRdvWMRYz0eK97hfOXcSQEaS-u8RS9Vj2laj1Y1ZSGWHjveuu-2dK9CmSvy2jjTLZU1lawmgXNW_yEBOqE_0PoVLEoFitfKnp01f1nq6OpXpq3AKsiny7rpypAPcLnN8OWIqzyWBdhQGamq2Aqp31VcBIN5Gx8TRbQUfOoBig11AE0VkgCL3QR5qWwQRw", "assets/stitch_wallpaper.jpg")

# 3. Enhance Header Nav and Action Buttons
html = html.replace('data-path="atoll-native-island" href="#"', 'href="#features"')
html = html.replace('data-path="interactive-notch-experience" href="#"', 'href="#interactive-preview"')
html = html.replace('data-path="system-hotkeys-and-shortcuts" href="#"', 'href="#shortcuts"')
html = html.replace('data-path="frequently-asked-questions" href="#"', 'href="#faqs"')

old_header_btns = '<div class="flex items-center gap-space-md"><a class="font-body-md text-body-md font-semibold text-pure-black bg-white hover:bg-on-surface transition-all px-5 py-2 rounded-full shadow-[0_0_20px_rgba(255,255,255,0.2)] flex items-center gap-space-xs" data-path="release-notes-and-download" href="#"><span class="material-symbols-outlined text-[18px]">download</span><span>Download Free</span></a><div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center"><span class="material-symbols-outlined text-on-primary text-[18px]">person</span></div></div>'
new_header_btns = """<div class="flex items-center gap-3">
  <a class="font-body-md text-body-md font-semibold text-pure-black bg-white hover:bg-neutral-200 transition-all px-4 py-2 rounded-full shadow-[0_0_20px_rgba(255,255,255,0.2)] flex items-center gap-2 group" href="downloads/Atoll.dmg" download="Atoll.dmg" onclick="trackEvent('download_dmg', 'conversion', 'Atoll.dmg')">
    <svg class="w-4 h-4 fill-current transition-transform group-hover:-translate-y-0.5" viewBox="0 0 24 24">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 0.92-2.87-.9.04-2 .6-2.64 1.35-.56.64-1.06 1.7-0.93 2.73 1.01.08 2.04-.46 2.65-1.21z"/>
    </svg>
    <span>Download Free</span>
  </a>
  <a href="https://github.com/SlimmyTee/Atoll" target="_blank" rel="noopener noreferrer" class="w-9 h-9 rounded-full bg-surface-container hover:bg-surface-bright border border-white/10 hover:border-white/20 flex items-center justify-center text-on-surface hover:text-white transition-all shadow-sm" title="View Source on GitHub">
    <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
      <path fill-rule="evenodd" clip-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"/>
    </svg>
  </a>
</div>"""
html = html.replace(old_header_btns, new_header_btns)

# 4. Hero DMG Download Button
old_hero_dmg = """<a class="w-full sm:w-auto px-6 py-2.5 rounded-full bg-white text-pure-black font-semibold font-body-md text-body-md hover:bg-on-surface transition-all shadow-[0_0_20px_rgba(255,255,255,0.25)] flex items-center justify-center gap-2" href="#">
<span class="material-symbols-outlined text-[18px]">download</span>
<span>Download DMG</span>
</a>"""
new_hero_dmg = """<a class="w-full sm:w-auto px-6 py-2.5 rounded-full bg-white text-pure-black font-semibold font-body-md text-body-md hover:bg-neutral-200 transition-all shadow-[0_0_20px_rgba(255,255,255,0.25)] flex items-center justify-center gap-2 group" href="downloads/Atoll.dmg" download="Atoll.dmg" onclick="trackEvent('download_dmg', 'conversion', 'Atoll.dmg')">
  <svg class="w-4 h-4 fill-current transition-transform group-hover:-translate-y-0.5" viewBox="0 0 24 24">
    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 0.92-2.87-.9.04-2 .6-2.64 1.35-.56.64-1.06 1.7-0.93 2.73 1.01.08 2.04-.46 2.65-1.21z"/>
  </svg>
  <span>Download DMG</span>
</a>"""
html = html.replace(old_hero_dmg, new_hero_dmg)

# 5. Bottom CTA DMG Button
old_cta_dmg = """<a class="w-full sm:w-auto px-8 py-3.5 rounded-full bg-white text-pure-black font-headline-sm text-[15px] font-bold hover:bg-on-surface transition-all shadow-[0_0_30px_rgba(255,255,255,0.3)] flex items-center justify-center gap-2" href="#">
<span class="material-symbols-outlined text-[20px]">download</span>
<span>Download Atoll for Mac</span>
<span class="font-label-badge text-[11px] px-2 py-0.5 rounded-full bg-surface-container-high/20 font-normal">704 KB</span>
</a>"""
new_cta_dmg = """<a class="w-full sm:w-auto px-8 py-3.5 rounded-full bg-white text-pure-black font-headline-sm text-[15px] font-bold hover:bg-neutral-200 transition-all shadow-[0_0_30px_rgba(255,255,255,0.3)] flex items-center justify-center gap-2.5 group" href="downloads/Atoll.dmg" download="Atoll.dmg" onclick="trackEvent('download_dmg', 'conversion', 'Atoll.dmg')">
  <svg class="w-5 h-5 fill-current transition-transform group-hover:-translate-y-0.5" viewBox="0 0 24 24">
    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 0.92-2.87-.9.04-2 .6-2.64 1.35-.56.64-1.06 1.7-0.93 2.73 1.01.08 2.04-.46 2.65-1.21z"/>
  </svg>
  <span>Download Atoll for Mac</span>
  <span class="font-label-badge text-[11px] px-2 py-0.5 rounded-full bg-black/10 font-normal">704 KB • Universal</span>
</a>"""
html = html.replace(old_cta_dmg, new_cta_dmg)

# 6. Simulator Album Art (Realistic playback)
old_sim_art = '<span class="material-symbols-outlined text-[20px] text-tertiary">graphic_eq</span>'
new_sim_art = '<img src="assets/album_art.jpg" alt="Dave" class="w-full h-full object-cover">'
html = html.replace(old_sim_art, new_sim_art, 1)

# 7. Section IDs for Smooth Scroll
html = html.replace('<!-- Interactive MacBook Pro Island Simulator -->\n<section class="', '<!-- Interactive MacBook Pro Island Simulator -->\n<section id="interactive-preview" class="')
html = html.replace('<!-- 3x2 Unified Bento Feature Matrix -->\n<section class="', '<!-- 3x2 Unified Bento Feature Matrix -->\n<section id="features" class="')
html = html.replace('<!-- Keyboard Shortcuts Command Matrix -->\n<section class="', '<!-- Keyboard Shortcuts Command Matrix -->\n<section id="shortcuts" class="')
html = html.replace('<!-- Clean Accordion FAQs -->\n<section class="', '<!-- Clean Accordion FAQs -->\n<section id="faqs" class="')

# 8. Footer Links
html = html.replace('data-path="release-notes-and-download" href="#"', 'href="downloads/Atoll.dmg" download="Atoll.dmg" onclick="trackEvent(\'download_dmg\', \'conversion\', \'Atoll.dmg\')"')
html = html.replace('data-path="privacy-manifesto" href="#"', 'href="https://github.com/SlimmyTee/Atoll" target="_blank" rel="noopener noreferrer"')

# 9. Realistic MacBook Pro Base (Magic Keyboard + Trackpad)
keyboard_base_html = """
        <!-- Authentic MacBook Pro Magic Keyboard & Trackpad Base -->
        <div class="macbook-base-chassis mt-2" id="macbook-base">
          <!-- Hinge Cylinder -->
          <div class="macbook-hinge-section">
            <div class="hinge-vent-left"></div>
            <div class="hinge-barrel">
              <span class="hinge-brand-engraving">MacBook Pro</span>
              <span class="hinge-sheen"></span>
            </div>
            <div class="hinge-vent-right"></div>
          </div>

          <!-- Upper Deck Aluminum Surface -->
          <div class="macbook-deck-surface">
            <div class="macbook-keyboard-and-speakers">
              <!-- Left Speaker Grille -->
              <div class="macbook-speaker-grille left-speaker" aria-hidden="true"></div>

              <!-- Recessed Keyboard Well -->
              <div class="macbook-keyboard-well">
                <!-- Row 1: Function Row -->
                <div class="kb-row row-fn">
                  <div class="kb-key key-esc" data-key="Escape"><span class="key-label">esc</span></div>
                  <div class="kb-key" data-key="F1"><span class="key-icon">🔅</span><span class="key-sub">F1</span></div>
                  <div class="kb-key" data-key="F2"><span class="key-icon">🔆</span><span class="key-sub">F2</span></div>
                  <div class="kb-key" data-key="F3"><span class="key-icon">⊞</span><span class="key-sub">F3</span></div>
                  <div class="kb-key" data-key="F4"><span class="key-icon">🔍</span><span class="key-sub">F4</span></div>
                  <div class="kb-key" data-key="F5"><span class="key-icon">🎙️</span><span class="key-sub">F5</span></div>
                  <div class="kb-key" data-key="F6"><span class="key-icon">🌙</span><span class="key-sub">F6</span></div>
                  <div class="kb-key" data-key="F7"><span class="key-icon">◀◀</span><span class="key-sub">F7</span></div>
                  <div class="kb-key" data-key="F8"><span class="key-icon">▶❚❚</span><span class="key-sub">F8</span></div>
                  <div class="kb-key" data-key="F9"><span class="key-icon">▶▶</span><span class="key-sub">F9</span></div>
                  <div class="kb-key" data-key="F10"><span class="key-icon">🔇</span><span class="key-sub">F10</span></div>
                  <div class="kb-key" data-key="F11"><span class="key-icon">🔉</span><span class="key-sub">F11</span></div>
                  <div class="kb-key" data-key="F12"><span class="key-icon">🔊</span><span class="key-sub">F12</span></div>
                  <div class="kb-key key-touchid" title="Touch ID Sensor"><div class="touchid-sensor-ring"></div></div>
                </div>

                <!-- Row 2: Number Row -->
                <div class="kb-row row-num">
                  <div class="kb-key" data-key="`"><span class="key-top">~</span><span class="key-bot">`</span></div>
                  <div class="kb-key" data-key="1"><span class="key-top">!</span><span class="key-bot">1</span></div>
                  <div class="kb-key" data-key="2"><span class="key-top">@</span><span class="key-bot">2</span></div>
                  <div class="kb-key" data-key="3"><span class="key-top">#</span><span class="key-bot">3</span></div>
                  <div class="kb-key" data-key="4"><span class="key-top">$</span><span class="key-bot">4</span></div>
                  <div class="kb-key" data-key="5"><span class="key-top">%</span><span class="key-bot">5</span></div>
                  <div class="kb-key" data-key="6"><span class="key-top">^</span><span class="key-bot">6</span></div>
                  <div class="kb-key" data-key="7"><span class="key-top">&amp;</span><span class="key-bot">7</span></div>
                  <div class="kb-key" data-key="8"><span class="key-top">*</span><span class="key-bot">8</span></div>
                  <div class="kb-key" data-key="9"><span class="key-top">(</span><span class="key-bot">9</span></div>
                  <div class="kb-key" data-key="0"><span class="key-top">)</span><span class="key-bot">0</span></div>
                  <div class="kb-key" data-key="-"><span class="key-top">_</span><span class="key-bot">-</span></div>
                  <div class="kb-key" data-key="="><span class="key-top">+</span><span class="key-bot">=</span></div>
                  <div class="kb-key key-delete" data-key="Backspace"><span class="key-label">delete</span></div>
                </div>

                <!-- Row 3: QWERTY Row -->
                <div class="kb-row row-qwerty">
                  <div class="kb-key key-tab" data-key="Tab"><span class="key-label">tab</span></div>
                  <div class="kb-key" data-key="q"><span class="key-main">Q</span></div>
                  <div class="kb-key" data-key="w"><span class="key-main">W</span></div>
                  <div class="kb-key" data-key="e"><span class="key-main">E</span></div>
                  <div class="kb-key" data-key="r"><span class="key-main">R</span></div>
                  <div class="kb-key" data-key="t"><span class="key-main">T</span></div>
                  <div class="kb-key" data-key="y"><span class="key-main">Y</span></div>
                  <div class="kb-key" data-key="u"><span class="key-main">U</span></div>
                  <div class="kb-key" data-key="i"><span class="key-main">I</span></div>
                  <div class="kb-key" data-key="o"><span class="key-main">O</span></div>
                  <div class="kb-key" data-key="p"><span class="key-main">P</span></div>
                  <div class="kb-key" data-key="["><span class="key-top">{</span><span class="key-bot">[</span></div>
                  <div class="kb-key" data-key="]"><span class="key-top">}</span><span class="key-bot">]</span></div>
                  <div class="kb-key key-backslash" data-key="\\"><span class="key-top">|</span><span class="key-bot">\\</span></div>
                </div>

                <!-- Row 4: Home Row (ASDF) -->
                <div class="kb-row row-asdf">
                  <div class="kb-key key-caps" data-key="CapsLock"><span class="caps-led"></span><span class="key-label">caps lock</span></div>
                  <div class="kb-key" data-key="a"><span class="key-main">A</span></div>
                  <div class="kb-key" data-key="s"><span class="key-main">S</span></div>
                  <div class="kb-key" data-key="d"><span class="key-main">D</span></div>
                  <div class="kb-key" data-key="f"><span class="key-main">F</span><span class="key-tactile-bump"></span></div>
                  <div class="kb-key" data-key="g"><span class="key-main">G</span></div>
                  <div class="kb-key" data-key="h"><span class="key-main">H</span></div>
                  <div class="kb-key" data-key="j"><span class="key-main">J</span><span class="key-tactile-bump"></span></div>
                  <div class="kb-key" data-key="k"><span class="key-main">K</span></div>
                  <div class="kb-key" data-key="l"><span class="key-main">L</span></div>
                  <div class="kb-key" data-key=";"><span class="key-top">:</span><span class="key-bot">;</span></div>
                  <div class="kb-key" data-key="'"><span class="key-top">\"</span><span class="key-bot">'</span></div>
                  <div class="kb-key key-return" data-key="Enter"><span class="key-label">return</span></div>
                </div>

                <!-- Row 5: Shift Row (ZXCV) -->
                <div class="kb-row row-shift">
                  <div class="kb-key key-lshift" data-key="Shift"><span class="key-label">shift</span></div>
                  <div class="kb-key" data-key="z"><span class="key-main">Z</span></div>
                  <div class="kb-key" data-key="x"><span class="key-main">X</span></div>
                  <div class="kb-key" data-key="c"><span class="key-main">C</span></div>
                  <div class="kb-key" data-key="v"><span class="key-main">V</span></div>
                  <div class="kb-key" data-key="b"><span class="key-main">B</span></div>
                  <div class="kb-key" data-key="n"><span class="key-main">N</span></div>
                  <div class="kb-key" data-key="m"><span class="key-main">M</span></div>
                  <div class="kb-key" data-key=","><span class="key-top">&lt;</span><span class="key-bot">,</span></div>
                  <div class="kb-key" data-key="."><span class="key-top">&gt;</span><span class="key-bot">.</span></div>
                  <div class="kb-key" data-key="/"><span class="key-top">?</span><span class="key-bot">/</span></div>
                  <div class="kb-key key-rshift" data-key="Shift"><span class="key-label">shift</span></div>
                </div>

                <!-- Row 6: Modifier Row -->
                <div class="kb-row row-mod">
                  <div class="kb-key key-fn" data-key="Fn"><span class="key-top">🌐</span><span class="key-bot">fn</span></div>
                  <div class="kb-key key-ctrl" data-key="Control"><span class="key-top">⌃</span><span class="key-bot">control</span></div>
                  <div class="kb-key key-lopt" data-key="Alt"><span class="key-top">⌥</span><span class="key-bot">option</span></div>
                  <div class="kb-key key-lcmd" data-key="Meta"><span class="key-top">⌘</span><span class="key-bot">command</span></div>
                  <div class="kb-key key-space" data-key=" "></div>
                  <div class="kb-key key-rcmd" data-key="Meta"><span class="key-top">⌘</span><span class="key-bot">command</span></div>
                  <div class="kb-key key-ropt" data-key="Alt"><span class="key-top">⌥</span><span class="key-bot">option</span></div>
                  <div class="kb-arrow-cluster">
                    <div class="kb-key key-arrow" data-key="ArrowLeft">◀</div>
                    <div class="kb-arrow-updown">
                      <div class="kb-key key-arrow key-arrow-up" data-key="ArrowUp">▲</div>
                      <div class="kb-key key-arrow key-arrow-down" data-key="ArrowDown">▼</div>
                    </div>
                    <div class="kb-key key-arrow" data-key="ArrowRight">▶</div>
                  </div>
                </div>
              </div>

              <!-- Right Speaker Grille -->
              <div class="macbook-speaker-grille right-speaker" aria-hidden="true"></div>
            </div>

            <!-- Lower Deck: Palm Rests & Force Touch Trackpad -->
            <div class="macbook-lower-deck">
              <div class="palmrest-area left-palmrest"></div>
              <div class="macbook-trackpad" id="macbook-trackpad" title="MacBook Pro Force Touch Trackpad">
                <div class="trackpad-glass-surface"></div>
              </div>
              <div class="palmrest-area right-palmrest"></div>
            </div>

            <!-- Front Lip with Thumb Opening Groove -->
            <div class="macbook-base-front-lip">
              <div class="macbook-base-thumb-groove"></div>
            </div>
          </div>

          <!-- Bottom Contact Shadow -->
          <div class="macbook-base-shadow"></div>
        </div>
"""

screen_shell_target = """<!-- Bottom Chin Label -->
<div class="absolute bottom-1 w-full text-center">
<span class="font-label-badge text-[10px] text-white/30 tracking-[0.2em] uppercase font-bold">MacBook Pro</span>
</div>
</div>"""

if screen_shell_target in html:
    html = html.replace(screen_shell_target, screen_shell_target + "\n" + keyboard_base_html)
    print("Attached keyboard base successfully!")
else:
    print("Warning: screen_shell_target not found!")

# 10. Add CSS for Keyboard Chassis
keyboard_css = """
/* MacBook Pro Keyboard Base Styles */
.macbook-base-chassis {
  position: relative;
  width: 100%;
  perspective: 1400px;
  z-index: 10;
  user-select: none;
}
.macbook-hinge-section {
  width: 100%;
  height: 12px;
  background: linear-gradient(180deg, #090a0d 0%, #16181f 50%, #0d0e12 100%);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 40px;
  position: relative;
  box-shadow: inset 0 2px 3px rgba(0, 0, 0, 0.9), 0 1px 0 rgba(255, 255, 255, 0.06);
}
.hinge-vent-left, .hinge-vent-right {
  width: 60px;
  height: 4px;
  background: #000000;
  border-radius: 2px;
}
.hinge-barrel {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}
.hinge-brand-engraving {
  font-family: -apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', sans-serif;
  font-size: 7.5px;
  font-weight: 600;
  letter-spacing: 0.22em;
  color: rgba(255, 255, 255, 0.28);
  text-transform: uppercase;
}
.hinge-sheen {
  position: absolute;
  top: 0; left: 0; right: 0; height: 1px;
  background: linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.15) 50%, transparent 100%);
}
.macbook-deck-surface {
  position: relative;
  background: linear-gradient(180deg, #171920 0%, #20232c 25%, #181a21 70%, #12141a 100%);
  border-radius: 0 0 26px 26px;
  padding: 14px 18px 10px 18px;
  transform: rotateX(6deg);
  transform-origin: top center;
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.12),
    0 2px 0 rgba(0, 0, 0, 0.8),
    inset 0 1px 0 rgba(255, 255, 255, 0.16),
    inset 0 -2px 4px rgba(0, 0, 0, 0.8);
}
.macbook-keyboard-and-speakers {
  display: flex;
  align-items: stretch;
  gap: 12px;
  width: 100%;
}
.macbook-speaker-grille {
  width: 34px;
  flex-shrink: 0;
  border-radius: 6px;
  background-color: #12141a;
  background-image: radial-gradient(circle, #000000 0.8px, transparent 0.9px);
  background-size: 3px 3px;
  opacity: 0.7;
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.8);
}
.macbook-keyboard-well {
  flex: 1;
  background: #08090c;
  border-radius: 8px;
  padding: 6px 7px;
  box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.95), inset 0 0 0 1px #000000;
  display: flex;
  flex-direction: column;
  gap: 3.5px;
}
.kb-row {
  display: flex;
  gap: 3.5px;
  width: 100%;
}
.row-fn { height: 20px; }
.row-num, .row-qwerty, .row-asdf, .row-shift, .row-mod { height: 24px; }
.kb-key {
  flex: 1;
  background: linear-gradient(180deg, #1e2027 0%, #14151b 100%);
  border-radius: 4px;
  color: rgba(255, 255, 255, 0.88);
  box-shadow: 0 1px 1px rgba(0, 0, 0, 0.85), inset 0 0.5px 0.5px rgba(255, 255, 255, 0.16);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-family: -apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', sans-serif;
  cursor: pointer;
  user-select: none;
  position: relative;
  transition: transform 0.06s ease, background 0.06s ease;
}
.kb-key:hover { background: linear-gradient(180deg, #252832 0%, #181a22 100%); color: #fff; }
.kb-key:active, .kb-key.pressed { transform: translateY(1.2px); background: #111217; }
.key-label { font-size: 7.5px; font-weight: 500; color: rgba(255, 255, 255, 0.75); }
.key-main { font-size: 9.5px; font-weight: 500; }
.key-top { font-size: 7.5px; line-height: 1; color: rgba(255, 255, 255, 0.7); }
.key-bot { font-size: 8.5px; line-height: 1.1; color: rgba(255, 255, 255, 0.9); }
.key-icon { font-size: 7.5px; line-height: 1; }
.key-sub { font-size: 5.5px; font-weight: 600; color: rgba(255, 255, 255, 0.45); }
.key-esc { flex: 1.5; }
.key-touchid { flex: 1.35; background: #0e0f14; border-radius: 5px; }
.touchid-sensor-ring { width: 13px; height: 13px; border-radius: 50%; border: 1px solid rgba(255, 255, 255, 0.28); }
.key-delete { flex: 1.5; align-items: flex-end; padding-right: 5px; }
.key-tab { flex: 1.5; align-items: flex-start; padding-left: 5px; }
.key-backslash { flex: 1.1; }
.key-caps { flex: 1.8; align-items: flex-start; padding-left: 5px; position: relative; }
.caps-led { position: absolute; top: 4px; left: 5px; width: 3px; height: 3px; border-radius: 50%; background: #22c55e; box-shadow: 0 0 4px #22c55e; }
.key-return { flex: 1.8; align-items: flex-end; padding-right: 5px; }
.key-lshift, .key-rshift { flex: 2.35; }
.key-fn, .key-ctrl { flex: 1; }
.key-lopt, .key-ropt { flex: 1.15; }
.key-lcmd, .key-rcmd { flex: 1.35; }
.key-space { flex: 5.6; }
.key-tactile-bump { position: absolute; bottom: 3px; width: 5px; height: 1px; background: rgba(255, 255, 255, 0.5); border-radius: 0.5px; }
.kb-arrow-cluster { flex: 3; display: flex; gap: 3px; height: 100%; }
.key-arrow { font-size: 7px; flex: 1; display: flex; align-items: center; justify-content: center; }
.kb-arrow-updown { flex: 1; display: flex; flex-direction: column; gap: 2px; height: 100%; }
.key-arrow-up, .key-arrow-down { height: calc(50% - 1px); }
.macbook-lower-deck { display: flex; align-items: center; justify-content: center; width: 100%; margin-top: 10px; margin-bottom: 4px; }
.palmrest-area { flex: 1; }
.macbook-trackpad {
  width: 280px; height: 120px; max-width: 36%;
  background: linear-gradient(180deg, #15171d 0%, #1a1c23 50%, #13151b 100%);
  border-radius: 8px;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.08), 0 1px 2px rgba(0, 0, 0, 0.4);
  position: relative;
}
.trackpad-glass-surface { position: absolute; inset: 0; }
.macbook-base-front-lip { width: 100%; height: 12px; display: flex; align-items: center; justify-content: center; position: relative; margin-top: 3px; }
.macbook-base-thumb-groove { width: 130px; height: 5px; background: linear-gradient(180deg, #0a0b0d 0%, #1c1f26 100%); border-radius: 0 0 7px 7px; }
.macbook-base-shadow { position: absolute; bottom: -20px; left: 2%; right: 2%; height: 35px; background: radial-gradient(ellipse at center, rgba(0, 0, 0, 0.85) 0%, transparent 75%); filter: blur(10px); pointer-events: none; z-index: -1; }
"""

html = html.replace('::-webkit-scrollbar{display:none;}</style>', '::-webkit-scrollbar{display:none;}\n' + keyboard_css + '</style>')

# 11. Typing scripts
typing_script = """
  // Interactive Physical Keyboard typing reflection
  document.querySelectorAll('.kb-key').forEach(k => {
    k.addEventListener('mousedown', () => k.classList.add('pressed'));
    k.addEventListener('mouseup', () => setTimeout(() => k.classList.remove('pressed'), 120));
    k.addEventListener('mouseleave', () => k.classList.remove('pressed'));
  });

  document.addEventListener('keydown', (e) => {
    const keyMatch = document.querySelector(`.kb-key[data-key="${CSS.escape(e.key.toLowerCase())}"]`) ||
                     document.querySelector(`.kb-key[data-key="${CSS.escape(e.key)}"]`) ||
                     document.querySelector(`.kb-key[data-key="${CSS.escape(e.code)}"]`);
    if (keyMatch) keyMatch.classList.add('pressed');
  });

  document.addEventListener('keyup', (e) => {
    const keyMatch = document.querySelector(`.kb-key[data-key="${CSS.escape(e.key.toLowerCase())}"]`) ||
                     document.querySelector(`.kb-key[data-key="${CSS.escape(e.key)}"]`) ||
                     document.querySelector(`.kb-key[data-key="${CSS.escape(e.code)}"]`);
    if (keyMatch) keyMatch.classList.remove('pressed');
  });
"""

html = html.replace('</script></main>', typing_script + '\n</script></main>')

with open("landing/index.html", "w") as f:
    f.write(html)

with open("index.html", "w") as f:
    f.write(html)

print("Generated landing/index.html and index.html cleanly!")
