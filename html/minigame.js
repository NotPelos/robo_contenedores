const card = document.getElementById('card');
const reader = document.getElementById('reader');
let active = false;
let initialX;
let timeStart, timeEnd;
const soundAccepted = new Audio('https://thomaspark.co/projects/among-us-card-swipe/audio/CardAccepted.mp3');
const soundDenied = new Audio('https://thomaspark.co/projects/among-us-card-swipe/audio/CardDenied.mp3');

let tarjeta; // Variable para almacenar la tarjeta

// Inicializar el minijuego oculto
document.getElementById('minigame-container').style.display = "none";

window.addEventListener('message', function(event) {
    if (event.data.type === "ui") {
        if (event.data.status) {
            document.getElementById('minigame-container').style.display = "flex";
            document.getElementById('soplete-container').style.display = "none";
            console.log("Minijuego de swipe mostrado");
        } else {
            document.getElementById('minigame-container').style.display = "none";
            console.log("Minijuego de swipe oculto");
        }
    } else if (event.data.type === "setTarjeta") {
        tarjeta = event.data.tarjeta;
        console.log("Tarjeta establecida: " + tarjeta);
    }
});

document.addEventListener('mousedown', dragStart);
document.addEventListener('mouseup', dragEnd);
document.addEventListener('mousemove', drag);
document.addEventListener('touchstart', dragStart);
document.addEventListener('touchend', dragEnd);
document.addEventListener('touchmove', drag);

function dragStart(e) {
  if (e.target !== card) return;

  if (e.type === 'touchstart') {
    initialX = e.touches[0].clientX;
  } else {
    initialX = e.clientX;
  }

  timeStart = performance.now();
  card.classList.remove('slide');
  active = true;
}

function dragEnd(e) {
  if (!active) return;

  e.preventDefault();
  let x;
  let status;

  if (e.type === 'touchend') {
    x = e.changedTouches[0].clientX - initialX;
  } else {
    x = e.clientX - initialX;
  }

  if (x < reader.offsetWidth) {
    status = 'invalid';
  }

  timeEnd = performance.now();
  card.classList.add('slide');
  active = false;

  setTranslate(0);
  setStatus(status);
}

function drag(e) {
  if (!active) return;

  e.preventDefault();
  let x;

  if (e.type === 'touchmove') {
    x = e.touches[0].clientX - initialX;
  } else {
    x = e.clientX - initialX;
  }

  setTranslate(x);
}

function setTranslate(x) {
  if (x < 0) {
    x = 0;
  } else if (x > reader.offsetWidth) {
    x = reader.offsetWidth;
  }

  x -= (card.offsetWidth / 2);

  card.style.transform = 'translateX(' + x + 'px)';
}

function setStatus(status) {
  if (typeof status === 'undefined') {
    let duration = timeEnd - timeStart;

    if (duration > 700) {
      status = 'slow';
    } else if (duration < 400) {
      status = 'fast';
    } else {
      status = 'valid';
    }
  }

  reader.dataset.status = status;
  playAudio(status);

  // Enviar resultado al servidor
  if (status === 'valid') {
    fetch(`https://${GetParentResourceName()}/swipeSuccess`, {
        method: 'POST',
        body: JSON.stringify({ tarjeta: tarjeta })
    });
  } else {
    fetch(`https://${GetParentResourceName()}/swipeFail`, { method: 'POST' });
  }
}

function playAudio(status) {
  soundDenied.pause();
  soundAccepted.pause();
  soundDenied.currentTime = 0;
  soundAccepted.currentTime = 0;

  if (status === 'valid') {
    soundAccepted.play();
  } else {
    soundDenied.play();
  }
}
