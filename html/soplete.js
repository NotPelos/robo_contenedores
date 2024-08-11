let heat = 20;
const maxHeat = 100;
const minHeat = 20;
const heatIncrement = 5;
const heatUpdateInterval = 100; // Intervalo en milisegundos para el control de repetición

let keyPressed = false; // Bandera para saber si la tecla está presionada

document.getElementById('soplete-container').style.display = "none";

window.addEventListener('message', function(event) {
    if (event.data.type === "soplete") {
        if (event.data.status) {
            document.getElementById('soplete-container').style.display = "flex";
            document.getElementById('minigame-container').style.display = "none";
            console.log("Minijuego del soplete mostrado");
        } else {
            document.getElementById('soplete-container').style.display = "none";
            console.log("Minijuego del soplete oculto");
        }
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const heatBarContainer = document.getElementById('heatBarContainer');

    // Crear y añadir las etiquetas 20º y 100º dentro del contenedor
    const labelStart = document.createElement('div');
    labelStart.id = 'heatLabelStart';
    labelStart.innerText = '20º';
    heatBarContainer.appendChild(labelStart);

    const labelEnd = document.createElement('div');
    labelEnd.id = 'heatLabelEnd';
    labelEnd.innerText = '100º';
    heatBarContainer.appendChild(labelEnd);

    const labelIns = document.createElement('div');
    labelIns.id = 'insLabel';
    labelIns.innerText = 'Pulsa E';
    heatBarContainer.appendChild(labelIns);

    updateHeatBar();
});

document.addEventListener('keydown', (event) => {
    if ((event.key === 'E' || event.key === 'e') && !keyPressed) {
        keyPressed = true; // Marca la tecla como presionada
        if (heat < maxHeat) {
            heat = Math.min(maxHeat, heat + heatIncrement); // Incrementa el calor
            updateHeatBar();
        }
    }
});

document.addEventListener('keyup', (event) => {
    if (event.key === 'E' || event.key === 'e') {
        keyPressed = false; // Marca la tecla como no presionada
    }
});

function updateHeatBar() {
    const heatBar = document.getElementById('heatBar');
    const progress = (heat - minHeat) / (maxHeat - minHeat);

    // Actualiza el ancho de la barra
    heatBar.style.width = `${progress * 100}%`;

    // Calcula el color de la barra en función del progreso
    const startColor = {
        r: 0,
        g: 221,
        b: 255
    }; // Color inicial (rgb de heatLabelStart)
    const endColor = {
        r: 222,
        g: 0,
        b: 0
    }; // Color final (rgb de heatLabelEnd)

    const r = Math.round(startColor.r + progress * (endColor.r - startColor.r));
    const g = Math.round(startColor.g + progress * (endColor.g - startColor.g));
    const b = Math.round(startColor.b + progress * (endColor.b - startColor.b));

    heatBar.style.background = `rgb(${r}, ${g}, ${b})`;

    if (heat >= maxHeat) {
        fetch(`https://${GetParentResourceName()}/sopleteSuccess`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(resp => {
            console.log(resp);
        }).catch(err => console.log('Error:', err));

        // Detén el intervalo de decrecimiento una vez que se alcanza el máximo
        clearInterval(decreaseHeatIntervalId);
    }
}

const decreaseHeatIntervalId = setInterval(() => {
    if (heat < maxHeat) {
        heat = Math.max(minHeat, heat - 3);
        updateHeatBar();
    }
}, 100);