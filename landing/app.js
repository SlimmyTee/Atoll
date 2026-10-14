document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const island = document.getElementById('dynamic-island');
  const pinBtn = document.getElementById('pin-island-btn');
  const compactArt = document.getElementById('compact-art');
  const compactWaveform = document.getElementById('compact-waveform');
  
  // Tabs
  const islandTabBtns = document.querySelectorAll('.island-tab-btn');
  const islandPanels = document.querySelectorAll('.island-tab-panel');
  const demoPills = document.querySelectorAll('.mode-pill');
  
  // Media Player
  const btnPlayPause = document.getElementById('btn-play-pause');
  const playPauseBtn = document.getElementById('btn-play-pause');
  const scrubberProgress = document.getElementById('scrubber-progress');
  const scrubberTrack = document.getElementById('scrubber-track');
  const timeCurrent = document.getElementById('time-current');
  const timeTotal = document.getElementById('time-total');
  const trackTitle = document.getElementById('track-title');
  const trackArtist = document.getElementById('track-artist');
  const mediaArtworkImg = document.getElementById('media-artwork-img');
  const mediaAmbientGlow = document.getElementById('media-ambient-glow');
  const btnSwitchSong = document.getElementById('btn-switch-song');
  const btnNext = document.getElementById('btn-next');
  const btnPrev = document.getElementById('btn-prev');
  
  // Shelf
  const shelfDropzone = document.getElementById('shelf-dropzone');
  const stagedFilesList = document.getElementById('staged-files-list');
  const shelfCountBadge = document.getElementById('shelf-count');
  
  // Timer
  const timerDisplay = document.getElementById('timer-display');
  const btnTimerToggle = document.getElementById('btn-timer-toggle');
  const btnTimerReset = document.getElementById('btn-timer-reset');
  const timerPresetBtns = document.querySelectorAll('.timer-preset-btn');
  
  // Quick Toggles
  const btnMuteToggle = document.getElementById('btn-mute-toggle');
  const muteText = document.getElementById('mute-text');
  const btnDndToggle = document.getElementById('btn-dnd-toggle');

  // FAQ
  const faqItems = document.querySelectorAll('.faq-item');

  // Clock
  const clockElem = document.getElementById('simulated-clock');

  // State
  let isPinned = false;
  let isAudioPlaying = true;
  let currentSongIndex = 0;
  let currentSeconds = 98; // 1:38
  let totalSeconds = 205;  // Streatham
  let playbackInterval = null;
  let collapseTimeout = null;

  // Timer State
  let timerDuration = 1500; // 25 min default
  let timerRemaining = 1500;
  let timerInterval = null;
  let isTimerRunning = false;

  const playIconSvg = '<svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
  const pauseIconSvg = '<svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>';
  
  const muteActiveSvg = '<svg id="mute-icon" viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M4.34 2.93L2.93 4.34 7.29 8.7 7 9H3v6h4l5 5v-6.59l4.18 4.18c-.65.49-1.38.88-2.18 1.11v2.06c1.34-.3 2.57-.92 3.61-1.75l2.05 2.05 1.41-1.41L4.34 2.93zM10 15.17L7.83 13H5v-2h2.83l.88-.88L10 11.41v3.76zM19 12c0 .82-.15 1.61-.41 2.34l1.53 1.53c.56-1.17.88-2.48.88-3.87 0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zm-2.5 0c0-.53-.1-1.04-.3-1.52l1.63-1.63c.42.92.67 1.94.67 3.15 0 1.77-1.02 3.29-2.5 4.03v-2.21c.42-.36.7-.86.7-1.42z"/></svg>';
  const muteInactiveSvg = '<svg id="mute-icon" viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>';

  // Song Library
  const demoSongs = [
    {
      title: 'Streatham',
      artist: 'Dave',
      album: 'PSYCHODRAMA',
      artwork: 'https://i.scdn.co/image/ab67616d0000b273565f69a950084775df6a4e77',
      duration: 205,
      glow: 'rgba(56, 189, 248, 0.7)'
    },
    {
      title: 'Starboy',
      artist: 'The Weeknd, Daft Punk',
      album: 'Starboy',
      artwork: 'https://i.scdn.co/image/ab67616d00001e025551adb75cf7c4737f93ed1d',
      duration: 230,
      glow: 'rgba(168, 85, 247, 0.7)'
    },
    {
      title: 'Psycho',
      artist: 'Dave',
      album: 'PSYCHODRAMA',
      artwork: 'https://i.scdn.co/image/ab67616d0000b273565f69a950084775df6a4e77',
      duration: 248,
      glow: 'rgba(37, 99, 235, 0.7)'
    }
  ];

  // 1. Expand / Collapse Island Logic
  function expandIsland() {
    clearTimeout(collapseTimeout);
    island.classList.remove('compact');
    island.classList.add('expanded');
  }

  function collapseIsland() {
    if (isPinned) return;
    clearTimeout(collapseTimeout);
    collapseTimeout = setTimeout(() => {
      if (!isPinned) {
        island.classList.remove('expanded');
        island.classList.add('compact');
      }
    }, 180);
  }

  island.addEventListener('mouseenter', expandIsland);
  island.addEventListener('mouseleave', collapseIsland);
  island.addEventListener('click', (e) => {
    if (island.classList.contains('compact')) {
      expandIsland();
    }
  });

  // Pin Toggle
  pinBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    isPinned = !isPinned;
    pinBtn.classList.toggle('pinned', isPinned);
    if (isPinned) {
      expandIsland();
    }
  });

  // 2. Tab Navigation
  function switchTab(tabName) {
    islandTabBtns.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.target === tabName);
    });
    islandPanels.forEach(panel => {
      panel.classList.toggle('active', panel.id === `panel-${tabName}`);
    });
    demoPills.forEach(pill => {
      pill.classList.toggle('active', pill.dataset.tab === tabName);
    });
    expandIsland();
  }

  islandTabBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      switchTab(btn.dataset.target);
    });
  });

  demoPills.forEach(pill => {
    pill.addEventListener('click', () => {
      switchTab(pill.dataset.tab);
    });
  });

  // 3. Media Player Controls
  function formatTime(secs) {
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  }

  function updateScrubber() {
    const percent = Math.min((currentSeconds / totalSeconds) * 100, 100);
    scrubberProgress.style.width = `${percent}%`;
    timeCurrent.textContent = formatTime(currentSeconds);
    timeTotal.textContent = formatTime(totalSeconds);
  }

  function loadSong(index) {
    const song = demoSongs[index];
    trackTitle.textContent = song.title;
    trackArtist.textContent = song.artist;
    mediaArtworkImg.src = song.artwork;
    compactArt.src = song.artwork;
    totalSeconds = song.duration;
    currentSeconds = 15;
    mediaAmbientGlow.style.background = `radial-gradient(circle, ${song.glow} 0%, transparent 70%)`;
    updateScrubber();
  }

  function togglePlayPause() {
    isAudioPlaying = !isAudioPlaying;
    playPauseBtn.innerHTML = isAudioPlaying ? pauseIconSvg : playIconSvg;
    
    // Waveform anim toggle
    compactWaveform.style.opacity = isAudioPlaying ? '1' : '0.4';
    const bars = compactWaveform.querySelectorAll('.bar');
    bars.forEach(b => {
      b.style.animationPlayState = isAudioPlaying ? 'running' : 'paused';
    });

    if (isAudioPlaying) {
      startPlaybackTimer();
    } else {
      clearInterval(playbackInterval);
    }
  }

  function startPlaybackTimer() {
    clearInterval(playbackInterval);
    playbackInterval = setInterval(() => {
      if (isAudioPlaying) {
        currentSeconds++;
        if (currentSeconds > totalSeconds) {
          currentSeconds = 0;
          nextSong();
        }
        updateScrubber();
      }
    }, 1000);
  }

  function nextSong() {
    currentSongIndex = (currentSongIndex + 1) % demoSongs.length;
    loadSong(currentSongIndex);
  }

  function prevSong() {
    currentSongIndex = (currentSongIndex - 1 + demoSongs.length) % demoSongs.length;
    loadSong(currentSongIndex);
  }

  btnPlayPause.addEventListener('click', (e) => {
    e.stopPropagation();
    togglePlayPause();
  });

  btnNext.addEventListener('click', (e) => {
    e.stopPropagation();
    nextSong();
  });

  btnPrev.addEventListener('click', (e) => {
    e.stopPropagation();
    prevSong();
  });

  btnSwitchSong.addEventListener('click', (e) => {
    e.stopPropagation();
    nextSong();
  });

  scrubberTrack.addEventListener('click', (e) => {
    e.stopPropagation();
    const rect = scrubberTrack.getBoundingClientRect();
    const pos = (e.clientX - rect.left) / rect.width;
    currentSeconds = Math.floor(pos * totalSeconds);
    updateScrubber();
  });

  // Initial song load
  loadSong(0);
  startPlaybackTimer();

  // 4. File Pocket / Shelf Logic
  const sampleFileNames = ['Q4_Financials.xlsx', 'AppIcon_Master.svg', 'PitchDeck_Final.pdf', 'CameraClip.mov'];
  
  function addMockFile() {
    const randomName = sampleFileNames[Math.floor(Math.random() * sampleFileNames.length)];
    const id = Date.now();
    const item = document.createElement('div');
    item.className = 'staged-file-item';
    item.dataset.id = id;
    item.innerHTML = `
      <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor" class="file-icon"><path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/></svg>
      <div class="file-info">
        <span class="file-name">${randomName}</span>
        <span class="file-size">${(Math.random() * 3 + 0.5).toFixed(1)} MB</span>
      </div>
      <button class="file-remove-btn" title="Remove">✕</button>
    `;

    item.querySelector('.file-remove-btn').addEventListener('click', (e) => {
      e.stopPropagation();
      item.remove();
      updateShelfCount();
    });

    stagedFilesList.appendChild(item);
    updateShelfCount();
  }

  function updateShelfCount() {
    const count = stagedFilesList.children.length;
    shelfCountBadge.textContent = count;
  }

  shelfDropzone.addEventListener('click', (e) => {
    e.stopPropagation();
    addMockFile();
  });

  stagedFilesList.querySelectorAll('.file-remove-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      btn.closest('.staged-file-item').remove();
      updateShelfCount();
    });
  });

  // 5. Focus Timer Logic
  function updateTimerDisplay() {
    const m = Math.floor(timerRemaining / 60);
    const s = Math.floor(timerRemaining % 60);
    timerDisplay.textContent = `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  }

  function toggleTimer() {
    isTimerRunning = !isTimerRunning;
    btnTimerToggle.textContent = isTimerRunning ? 'Pause' : 'Start Focus';
    btnTimerToggle.classList.toggle('running', isTimerRunning);

    if (isTimerRunning) {
      timerInterval = setInterval(() => {
        if (timerRemaining > 0) {
          timerRemaining--;
          updateTimerDisplay();
        } else {
          clearInterval(timerInterval);
          isTimerRunning = false;
          btnTimerToggle.textContent = 'Completed!';
          btnTimerToggle.classList.remove('running');
        }
      }, 1000);
    } else {
      clearInterval(timerInterval);
    }
  }

  btnTimerToggle.addEventListener('click', (e) => {
    e.stopPropagation();
    toggleTimer();
  });

  btnTimerReset.addEventListener('click', (e) => {
    e.stopPropagation();
    clearInterval(timerInterval);
    isTimerRunning = false;
    timerRemaining = timerDuration;
    btnTimerToggle.textContent = 'Start Focus';
    btnTimerToggle.classList.remove('running');
    updateTimerDisplay();
  });

  timerPresetBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      timerPresetBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      timerDuration = parseInt(btn.dataset.time, 10);
      timerRemaining = timerDuration;
      clearInterval(timerInterval);
      isTimerRunning = false;
      btnTimerToggle.textContent = 'Start Focus';
      btnTimerToggle.classList.remove('running');
      updateTimerDisplay();
    });
  });

  // 6. Quick Toggles
  let isMuted = false;
  btnMuteToggle.addEventListener('click', (e) => {
    e.stopPropagation();
    isMuted = !isMuted;
    btnMuteToggle.classList.toggle('active', isMuted);
    const oldIcon = btnMuteToggle.querySelector('#mute-icon');
    if (oldIcon) {
      oldIcon.outerHTML = isMuted ? muteActiveSvg : muteInactiveSvg;
    }
    muteText.textContent = isMuted ? 'Unmute Audio' : 'Mute Audio';
  });

  let isDnd = false;
  btnDndToggle.addEventListener('click', (e) => {
    e.stopPropagation();
    isDnd = !isDnd;
    btnDndToggle.classList.toggle('active', isDnd);
  });

  // 7. FAQ Accordion
  faqItems.forEach(item => {
    const questionBtn = item.querySelector('.faq-question');
    questionBtn.addEventListener('click', () => {
      const isOpen = item.classList.contains('open');
      faqItems.forEach(i => i.classList.remove('open'));
      if (!isOpen) {
        item.classList.add('open');
      }
    });
  });

  // 7b. Smart Meeting Launcher & Chrome Multi-Account Toast
  const btnJoinMeeting = document.getElementById('btn-join-meeting');
  const meetingToast = document.getElementById('meeting-toast');
  const demoAlertBtn = document.getElementById('demo-tab-alert');

  if (btnJoinMeeting && meetingToast) {
    btnJoinMeeting.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      meetingToast.classList.add('visible');
      setTimeout(() => {
        meetingToast.classList.remove('visible');
      }, 3500);
    });
  }

  if (demoAlertBtn) {
    demoAlertBtn.addEventListener('click', () => {
      switchTab('dashboard');
      expandIsland();
      if (meetingToast) {
        meetingToast.innerHTML = '<svg viewBox="0 0 24 24" width="15" height="15" fill="#34c759"><path d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"/></svg><span>🔔 Meeting starting in 1 min • Auto-popped from notch</span>';
        meetingToast.classList.add('visible');
        setTimeout(() => meetingToast.classList.remove('visible'), 4000);
      }
      // Auto-collapse after 8 seconds if not pinned or hovered
      setTimeout(() => {
        collapseIsland();
      }, 8000);
    });
  }

  // 8. Live Simulated Clock
  function updateClock() {
    const now = new Date();
    const options = { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' };
    clockElem.textContent = now.toLocaleDateString('en-US', options);
  }
  updateClock();
  setInterval(updateClock, 30000);

  // Keyboard shortcut Esc collapses island
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      isPinned = false;
      pinBtn.classList.remove('pinned');
      collapseIsland();
    }
  });
});
